locals {
  # renovate: datasource=custom.html depName=Fedora-Everything-netinst-x86_64 versioning=regex:^(?<major>[0-9]+)-(?<minor>[0-9]+)\.(?<patch>[0-9]+)$ extractVersion=(^|/)Fedora-Everything-netinst-x86_64-(?<version>[0-9.-]+)\.iso$ registryUrl=https://download.fedoraproject.org/pub/fedora/linux/releases/41/Everything/x86_64/iso/
  fedora41_version = "41-1.4"
  # renovate: datasource=custom.html depName=Fedora-Silverblue-ostree-x86_64 versioning=regex:^(?<major>[0-9]+)-(?<minor>[0-9]+)\.(?<patch>[0-9]+)$ extractVersion=(^|/)Fedora-Silverblue-ostree-x86_64-(?<version>[0-9.-]+)\.iso$ registryUrl=https://download.fedoraproject.org/pub/fedora/linux/releases/41/Silverblue/x86_64/iso/
  silverblue41_version = "41-1.4"
  # renovate: datasource=custom.html depName=Fedora-Everything-netinst-x86_64 versioning=regex:^(?<major>[0-9]+)-(?<minor>[0-9]+)\.(?<patch>[0-9]+)$ extractVersion=(^|/)Fedora-Everything-netinst-x86_64-(?<version>[0-9.-]+)\.iso$ registryUrl=https://download.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/iso/
  fedora42_version = "42-1.1"
  # renovate: datasource=custom.html depName=Fedora-Silverblue-ostree-x86_64 versioning=regex:^(?<major>[0-9]+)-(?<minor>[0-9]+)\.(?<patch>[0-9]+)$ extractVersion=(^|/)Fedora-Silverblue-ostree-x86_64-(?<version>[0-9.-]+)\.iso$ registryUrl=https://download.fedoraproject.org/pub/fedora/linux/releases/42/Silverblue/x86_64/iso/
  silverblue42_version = "42-1.1"
  # renovate: datasource=custom.html depName=Fedora-Everything-netinst-x86_64 versioning=regex:^(?<major>[0-9]+)-(?<minor>[0-9]+)\.(?<patch>[0-9]+)$ extractVersion=(^|/)Fedora-Everything-netinst-x86_64-(?<version>[0-9.-]+)\.iso$ registryUrl=https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/iso/
  fedora43_version = "43-1.6"
  # renovate: datasource=custom.html depName=Fedora-Silverblue-ostree-x86_64 versioning=regex:^(?<major>[0-9]+)-(?<minor>[0-9]+)\.(?<patch>[0-9]+)$ extractVersion=(^|/)Fedora-Silverblue-ostree-x86_64-(?<version>[0-9.-]+)\.iso$ registryUrl=https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Silverblue/x86_64/iso/
  silverblue43_version = "43-1.6"
}

source "qemu" "fedora" {
  vga = "virtio"
  cpus = 2
  memory = 8192
  headless = var.headless
  qmp_enable = var.headless
  shutdown_command = "sudo shutdown -P now"
  disk_discard = "unmap"
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /images/pxeboot/vmlinuz console=ttyS0 systemd.journald.forward_to_console=1 ",
    "inst.notmux inst.cmdline inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/fedora.ks<enter><wait>",
    "initrd /images/pxeboot/initrd.img<enter><wait10>",
    "boot<enter>"
  ]
  efi_firmware_code = local.efi_firmware_code
  efi_firmware_vars = local.efi_firmware_vars
  qemuargs = [["-cpu", "host"], ["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  source "qemu.fedora" {
    name = "fedora41"
    output_directory = "output-${source.name}"
    iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-${local.fedora41_version}.iso"
    iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/41/Everything/x86_64/iso/Fedora-Everything-${local.fedora41_version}-x86_64-CHECKSUM"
    http_content = {
      "/fedora.ks" = templatefile("${path.root}/fedora.ks", { path = path, hostname = source.name })
    }
  }

  source "qemu.fedora" {
    name = "silverblue41"
    output_directory = "output-${source.name}"
    iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Silverblue/x86_64/iso/Fedora-Silverblue-ostree-x86_64-${local.silverblue41_version}.iso"
    iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/41/Silverblue/x86_64/iso/Fedora-Silverblue-${local.silverblue41_version}-x86_64-CHECKSUM"
    http_content = {
      "/fedora.ks" = templatefile("${path.root}/fedora-silverblue.ks", { path = path, hostname = source.name, version = "41" })
    }
  }

  source "qemu.fedora" {
    name = "fedora42"
    output_directory = "output-${source.name}"
    iso_url = "https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-${local.fedora42_version}.iso"
    iso_checksum = "file:https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/iso/Fedora-Everything-${local.fedora42_version}-x86_64-CHECKSUM"
    http_content = {
      "/fedora.ks" = templatefile("${path.root}/fedora.ks", { path = path, hostname = source.name })
    }
  }

  source "qemu.fedora" {
    name = "silverblue42"
    output_directory = "output-${source.name}"
    iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Silverblue/x86_64/iso/Fedora-Silverblue-ostree-x86_64-${local.silverblue42_version}.iso"
    iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/42/Silverblue/x86_64/iso/Fedora-Silverblue-${local.silverblue42_version}-x86_64-CHECKSUM"
    http_content = {
      "/fedora.ks" = templatefile("${path.root}/fedora-silverblue.ks", { path = path, hostname = source.name, version = "42" })
    }
  }

  source "qemu.fedora" {
    name = "fedora43"
    output_directory = "output-${source.name}"
    iso_url = "https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-${local.fedora43_version}.iso"
    iso_checksum = "file:https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/iso/Fedora-Everything-${local.fedora43_version}-x86_64-CHECKSUM"
    http_content = {
      "/fedora.ks" = templatefile("${path.root}/fedora.ks", { path = path, hostname = source.name })
    }
  }

  source "qemu.fedora" {
    name = "silverblue43"
    output_directory = "output-${source.name}"
    iso_url = "https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Silverblue/x86_64/iso/Fedora-Silverblue-ostree-x86_64-${local.silverblue43_version}.iso"
    iso_checksum = "file:https://dl.fedoraproject.org/pub/fedora/linux/releases/43/Silverblue/x86_64/iso/Fedora-Silverblue-${local.silverblue43_version}-x86_64-CHECKSUM"
    http_content = {
      "/fedora.ks" = templatefile("${path.root}/fedora-silverblue.ks", { path = path, hostname = source.name, version = "43" })
    }
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
