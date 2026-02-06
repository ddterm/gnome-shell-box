locals {
  # renovate: datasource=custom.html depName=archlinux-iso versioning=loose extractVersion=(^|/)(?<version>[0-9.]+)/$ registryUrl=https://geo.mirror.pkgbuild.com/iso/
  archlinux_version = "2026.02.01"
}

source "qemu" "archlinux" {
  iso_url = "https://geo.mirror.pkgbuild.com/iso/${local.archlinux_version}/archlinux-${local.archlinux_version}-x86_64.iso"
  iso_checksum = "file:https://geo.mirror.pkgbuild.com/iso/${local.archlinux_version}/sha256sums.txt"
  vga = "virtio"
  cpus = 2
  memory = 8192
  headless = var.headless
  shutdown_command = "/sbin/poweroff"
  qmp_enable = var.headless
  disk_discard = "unmap"
  http_content = {
    "/archinstall-config.json" = templatefile("${path.root}/archinstall-config.json", { path = path, hostname = "archlinux" })
    "/archinstall-creds.json" = file("${path.root}/archinstall-creds.json")
    "/vagrant.pub" = file("${path.root}/keys/vagrant.pub")
  }
  ssh_username = "root"
  ssh_private_key_file = "${path.root}/keys/vagrant"
  boot_wait = "1m"
  boot_command = [
    "curl -o /root/.ssh/authorized_keys 'http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant.pub'<enter>",
  ]
  efi_firmware_code = local.efi_firmware_code
  efi_firmware_vars = local.efi_firmware_vars
  qemuargs = [["-cpu", "host"], ["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  sources = [
    "source.qemu.archlinux"
  ]

  provisioner "shell" {
    inline = [
      "sgdisk --align-end --clear --new 0:0:+1M --typecode=0:ef02 --change-name=0:'BIOS boot partition' --new 0:0:+300M --typecode=0:ef00 --change-name=0:'EFI system partition' --new 0:0:0 --typecode=0:8304 --change-name=0:'Arch Linux root' /dev/vda",
      "udevadm settle",
      "partprobe /dev/vda",
      "udevadm settle",
      "mkfs.btrfs /dev/disk/by-partlabel/$(systemd-escape 'Arch Linux root')",
      "mount --mkdir -o discard,compress-force=zstd /dev/disk/by-partlabel/$(systemd-escape 'Arch Linux root') /mnt",
      "mkfs.fat -F 32 -S 4096 /dev/disk/by-partlabel/$(systemd-escape 'EFI system partition')",
      "mount --mkdir /dev/disk/by-partlabel/$(systemd-escape 'EFI system partition') /mnt/boot",
    ]
  }

  provisioner "shell" {
    inline = [
      "archinstall --config-url 'http://${build.PackerHTTPAddr}/archinstall-config.json' --creds-url 'http://${build.PackerHTTPAddr}/archinstall-creds.json' --silent --debug"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'vagrant ALL=(ALL:ALL) NOPASSWD: ALL' > /mnt/etc/sudoers.d/vagrant",
      "mkdir -p /mnt/root/.ssh",
      "mkdir -p /mnt/home/vagrant/.ssh",
    ]
  }

  provisioner "file" {
    source = "${path.root}/keys/vagrant.pub"
    destination = "/mnt/root/.ssh/authorized_keys"
  }

  provisioner "file" {
    source = "${path.root}/keys/vagrant.pub"
    destination = "/mnt/home/vagrant/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "chmod 0644 /mnt/home/vagrant/.ssh/authorized_keys",
      "arch-chroot /mnt chown vagrant /home/vagrant/.ssh /home/vagrant/.ssh/authorized_keys"
    ]
  }

  provisioner "file" {
    direction = "download"
    destination = "${var.log_dir}/${build.PackerRunUUID}/"
    source = "/var/log/archinstall/"
  }

  error-cleanup-provisioner "file" {
    direction = "download"
    destination = "${var.log_dir}/${build.PackerRunUUID}/"
    source = "/var/log/archinstall/"
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
