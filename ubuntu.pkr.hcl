locals {
  # renovate: datasource=custom.html depName=ubuntu-release versioning=ubuntu extractVersion=(^|/)(?<version>[0-9.]+)/$ registryUrl=https://releases.ubuntu.com/
  ubuntu2404_version = "24.04.3"
  # renovate: datasource=custom.html depName=ubuntu-release versioning=ubuntu extractVersion=(^|/)(?<version>[0-9.]+)/$ registryUrl=https://releases.ubuntu.com/
  ubuntu2504_version = "25.04"
}

source "qemu" "ubuntu" {
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
    "linux /casper/vmlinuz autoinstall console=ttyS0 ",
    "cloud-config-url=\"http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu-autoinstall.yml\" --- <enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
  efi_firmware_code = local.efi_firmware_code
  efi_firmware_vars = local.efi_firmware_vars
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  source "qemu.ubuntu" {
    name = "ubuntu2404"
    output_directory = "output-${source.name}"
    iso_url = "https://releases.ubuntu.com/${local.ubuntu2404_version}/ubuntu-${local.ubuntu2404_version}-desktop-amd64.iso"
    iso_checksum = "file:https://releases.ubuntu.com/${local.ubuntu2404_version}/SHA256SUMS"
    http_content = {
      "/ubuntu-autoinstall.yml" = templatefile("${path.root}/ubuntu-autoinstall.yml", { path = path, hostname = source.name })
    }
  }

  source "qemu.ubuntu" {
    name = "ubuntu2504"
    output_directory = "output-${source.name}"
    iso_url = "https://releases.ubuntu.com/${local.ubuntu2504_version}/ubuntu-${local.ubuntu2504_version}-desktop-amd64.iso"
    iso_checksum = "file:https://releases.ubuntu.com/${local.ubuntu2504_version}/SHA256SUMS"
    http_content = {
      "/ubuntu-autoinstall.yml" = templatefile("${path.root}/ubuntu-autoinstall.yml", { path = path, hostname = source.name })
    }
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get clean -y",
      "sudo fstrim -av --quiet-unsupported",
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
