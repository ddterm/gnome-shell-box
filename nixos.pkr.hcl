variable "nixos_channel" {
  type = string
  default = "25.05"
}

data "http" "nixos_iso_checksum" {
  url = "https://channels.nixos.org/nixos-${var.nixos_channel}/latest-nixos-minimal-x86_64-linux.iso.sha256"
}

local "nixos_iso_checksum_split" {
  expression = compact(split(" ", data.http.nixos_iso_checksum.body))
}

local "nixos_iso_checksum" {
  expression = trimspace(local.nixos_iso_checksum_split[0])
}

local "nixos_iso_name" {
  expression = trimspace(local.nixos_iso_checksum_split[1])
}

local "nixos_iso_dir" {
  expression = regex_replace(local.nixos_iso_name, "nixos-minimal-(.*)-x86_64-linux.iso", "nixos-$1")
}

source "qemu" "nixos" {
  iso_url = "https://releases.nixos.org/nixos/${var.nixos_channel}/${local.nixos_iso_dir}/${local.nixos_iso_name}"
  iso_checksum = "sha256:${local.nixos_iso_checksum}"
  vga = "virtio"
  cpus = 2
  memory = 4096
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
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
  qemuargs = [["-serial", "stdio"]]
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
    content = templatefile("${path.root}/nix/configuration.nix", { path = path, state_version = var.nixos_channel })
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
      include = [
        "${path.root}/ovmf/OVMF_CODE.4m.fd",
        "${path.root}/output-${source.name}/efivars.fd",
        "${path.root}/ovmf/edk2.License.txt",
        "${path.root}/ovmf/OvmfPkg.License.txt",
      ]
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/nixos"
      version = local.version
    }
  }
}
