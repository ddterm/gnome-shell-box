locals {
  # renovate: datasource=custom.html depName=openSUSE-Leap-NET-x86_64 versioning=regex:^(?<major>[0-9]+)\.(?<minor>[0-9]+)-NET-x86_64-Build(?<patch>[0-9]+)\.(?<revision>[0-9]+)$ extractVersion=(^|/)openSUSE-Leap-(?<version>[^/]+)-Media\.iso$ registryUrl=https://download.opensuse.org/distribution/leap/15.6/iso/
  opensuseleap156_version = "15.6-NET-x86_64-Build710.3"
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

source "qemu" "opensuse" {
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  qmp_enable = var.headless
  shutdown_command = "sudo /sbin/halt -h -p"
  disk_discard = "unmap"
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /boot/x86_64/loader/linux netsetup=dhcp lang=en_US textmode=1 ssh=0 sshd=0 linuxrc.log=/dev/ttyS0 <wait>",
    "autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/opensuse.xml<enter><wait>",
    "initrd /boot/x86_64/loader/initrd<enter><wait>",
    "boot<enter>"
  ]
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  source "qemu.opensuse" {
    name = "opensuseleap156"
    output_directory = "output-${source.name}"
    iso_url = "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-${local.opensuseleap156_version}-Media.iso"
    iso_checksum = "file:https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-${local.opensuseleap156_version}-Media.iso.sha256"
    http_content = {
      "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = source.name, product = "Leap", security = "apparmor" })
    }
  }

  source "qemu.opensuse" {
    name = "opensusetumbleweed"
    output_directory = "output-${source.name}"
    iso_url = "https://download.opensuse.org/tumbleweed/iso/${local.opensusetumbleweed_iso_name}"
    iso_checksum = "sha256:${local.opensusetumbleweed_iso_checksum}"
    http_content = {
      "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = source.name, product = "openSUSE", security = "selinux" })
    }
  }

  provisioner "shell" {
    inline = [
      "sudo zypper clean --all",
      "sudo fstrim -av --quiet-unsupported",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
      include = [
        "${path.root}/ovmf/OVMF_CODE.4m.fd",
        "${path.root}/output-${source.name}/efivars.fd",
        "${path.root}/ovmf/edk2.License.txt",
        "${path.root}/ovmf/OvmfPkg.License.txt",
      ]
      compression_level = 9
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/${source.name}"
      version = local.version
    }
  }
}
