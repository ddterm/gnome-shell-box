locals {
  # renovate: datasource=custom.html depName=nixos versioning=regex:^(?<major>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)\.[0-9a-f]+$ extractVersion=(^|/)nixos-minimal-(?<version>[^/]+)-x86_64-linux\.iso$ registryUrl=https://channels.nixos.org/nixos-25.11
  nixos_build = "25.11.5198.e576e3c9cf9b"
}

local "nixos_channel" {
  expression = regex("^[0-9]+\\.[0-9]+", local.nixos_build)
}

local "nixos_iso_url" {
  expression = "https://releases.nixos.org/nixos/${local.nixos_channel}/nixos-${local.nixos_build}/nixos-minimal-${local.nixos_build}-x86_64-linux.iso"
}

# https://github.com/hashicorp/go-getter/issues/396
data "http" "nixos_iso_checksum" {
  url = "${local.nixos_iso_url}.sha256"
}

source "qemu" "nixos" {
  iso_url = "${local.nixos_iso_url}"
  iso_checksum = "sha256:${split(" ", data.http.nixos_iso_checksum.body)[0]}"
  vga = "virtio"
  cpus = 2
  memory = 8192
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = var.headless
  disk_discard = "unmap"
  ssh_timeout = "1h"
  ssh_username = "root"
  ssh_password = "vagrant"
  boot_wait = "1m"
  boot_command = [
    "sudo passwd root<enter><wait>",
    "vagrant<enter><wait>",
    "vagrant<enter><wait>",
  ]
  efi_firmware_code = local.efi_firmware_code
  efi_firmware_vars = local.efi_firmware_vars
  qemuargs = [["-cpu", "host"], ["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  sources = [
    "source.qemu.nixos"
  ]

  provisioner "shell" {
    inline = [
      "parted /dev/vda -- mklabel gpt",
      "parted /dev/vda -- mkpart primary 512MB -8GB",
      "parted /dev/vda -- mkpart primary linux-swap -8GB 100%",
      "parted /dev/vda -- mkpart ESP fat32 1MB 512MB",
      "parted /dev/vda -- set 3 esp on",

      "mkfs.btrfs -L nixos /dev/vda1",
      "mkswap -L swap /dev/vda2",
      "swapon /dev/vda2",
      "mkfs.fat -F 32 -n boot /dev/vda3",
      "mount -o discard /dev/disk/by-label/nixos /mnt",
      "mkdir -p /mnt/boot/efi",
      "mount /dev/disk/by-label/boot /mnt/boot/efi",
      "nixos-generate-config --root /mnt",
    ]
  }

  provisioner "file" {
    sources = [
      "${path.root}/nix/bootloader.nix",
      "${path.root}/nix/vagrant-hostname.nix",
      "${path.root}/nix/vagrant-network.nix",
      "${path.root}/nix/vagrant.nix",
    ]
    destination = "/mnt/etc/nixos/"
  }

  provisioner "file" {
    content = templatefile("${path.root}/nix/configuration.nix", { path = path, state_version = local.nixos_channel })
    destination = "/mnt/etc/nixos/configuration.nix"
  }

  provisioner "shell" {
    inline = [
      "nixos-install",
      "echo 'nix-env --delete-generations old; nix-collect-garbage -d; fstrim -av --quiet-unsupported' | nixos-enter"
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
