locals {
  # renovate: datasource=custom.html depName=openSUSE-Leap-NET-x86_64 versioning=regex:^(?<major>[0-9]+)\.(?<minor>[0-9]+)-NET-x86_64-Build(?<patch>[0-9]+)\.(?<revision>[0-9]+)$ extractVersion=(^|/)openSUSE-Leap-(?<version>[^/]+)-Media\.iso$ registryUrl=https://download.opensuse.org/distribution/leap/15.6/iso/
  opensuseleap156_version = "15.6-NET-x86_64-Build710.3"
  # renovate: datasource=custom.html depName=openSUSE-Leap-16.0-online-installer-x86_64 versioning=regex:^(?<major>[0-9]+)\.(?<minor>[0-9]+)-online-installer-x86_64-Build(?<patch>[0-9]+)\.(?<revision>[0-9]+)$ extractVersion=(^|/)Leap-(?<version>[^/]+)\.install\.iso$ registryUrl=https://download.opensuse.org/distribution/leap/16.0/offline/
  opensuseleap16_version = "16.0-online-installer-x86_64-Build171.1"
}

data "http" "opensusetumbleweed_iso_checksum" {
  url = "https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso.sha256"
}

local "opensusetumbleweed_iso_checksum_split" {
  expression = compact(split(" ", data.http.opensusetumbleweed_iso_checksum.body))
}

local "opensusetumbleweed_iso_checksum" {
  expression = trimspace(local.opensusetumbleweed_iso_checksum_split[0])
}

local "opensusetumbleweed_iso_name" {
  expression = trimspace(local.opensusetumbleweed_iso_checksum_split[1])
}

local "autoyast_boot_command" {
  expression = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /boot/x86_64/loader/linux netsetup=dhcp lang=en_US textmode=1 ssh=0 sshd=0 linuxrc.log=/dev/ttyS0 ",
    "autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/opensuse.xml<enter><wait>",
    "initrd /boot/x86_64/loader/initrd<enter><wait>",
    "boot<enter>"
  ]
}

local "agama_boot_command" {
  expression = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /boot/x86_64/loader/linux console=ttyS0 systemd.journald.forward_to_console=1 ",
    "ip=dhcp inst.self_update=0 live.password=vagrant<enter><wait>",
    "initrd /boot/x86_64/loader/initrd<enter><wait>",
    "boot<enter>"
  ]
}

source "qemu" "opensuse" {
  vga = "virtio"
  cpus = 2
  memory = 8192
  headless = var.headless
  qmp_enable = var.headless
  shutdown_command = "/sbin/halt -h -p"
  disk_discard = "unmap"
  ssh_timeout = "1h"
  ssh_username = "root"
  ssh_password = "vagrant"
  efi_firmware_code = local.efi_firmware_code
  efi_firmware_vars = local.efi_firmware_vars
  qemuargs = [["-cpu", "host"], ["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  source "qemu.opensuse" {
    name = "opensuseleap156"
    output_directory = "output-${source.name}"
    iso_url = "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-${local.opensuseleap156_version}-Media.iso"
    iso_checksum = "file:https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-${local.opensuseleap156_version}-Media.iso.sha256"
    boot_command = local.autoyast_boot_command
    http_content = {
      "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = source.name, product = "Leap", security = "apparmor" })
    }
  }

  source "qemu.opensuse" {
    name = "opensuseleap16"
    output_directory = "output-${source.name}"
    iso_url = "https://download.opensuse.org/distribution/leap/16.0/offline/Leap-${local.opensuseleap16_version}.install.iso"
    iso_checksum = "file:https://download.opensuse.org/distribution/leap/16.0/offline/Leap-${local.opensuseleap16_version}.install.iso.sha256"
    boot_command = local.agama_boot_command
    boot_wait = "9s"
    http_content = {
      "/opensuse.json" = templatefile("${path.root}/opensuse.json", { path = path, hostname = source.name, product = "openSUSE_Leap" })
    }
  }

  source "qemu.opensuse" {
    name = "opensusetumbleweed"
    output_directory = "output-${source.name}"
    iso_url = "https://download.opensuse.org/tumbleweed/iso/${local.opensusetumbleweed_iso_name}"
    iso_checksum = "sha256:${local.opensusetumbleweed_iso_checksum}"
    boot_command = local.autoyast_boot_command
    http_content = {
      "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = source.name, product = "openSUSE", security = "selinux" })
    }
  }

  provisioner "shell" {
    only = ["qemu.opensuseleap16"]
    pause_before = "1m"
    inline = [
      "sed -i 's/\\bsystemd\\.\\S*//g; s/\\bconsole=\\S*//g' /run/agama/cmdline.d/kernel.conf",
      "agama config load http://${build.PackerHTTPAddr}/opensuse.json",
      "agama install",
    ]
  }

  provisioner "shell" {
    only = ["qemu.opensuseleap16"]
    inline = ["agama finish"]
    expect_disconnect = true
    pause_after = "1m"
  }

  provisioner "shell" {
    inline = [
      "zypper clean --all",
      "fstrim -av --quiet-unsupported",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
      include = flatten([
        local.ovmf_include,
        "output-${source.name}/efivars.fd",
      ])
      compression_level = 9
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/${source.name}"
      version = local.version
    }
  }
}
