locals {
  # renovate: datasource=custom.html depName=debian-release extractVersion=(^|/)(?<version>[0-9.]+)/$ registryUrl=https://cdimage.debian.org/cdimage/release/
  debian13_version = "13.2.0"
}

source "qemu" "debian" {
  vga = "virtio"
  cpus = 2
  memory = 8192
  headless = var.headless
  qmp_enable = var.headless
  shutdown_command = "shutdown -P now"
  disk_discard = "unmap"
  ssh_timeout = "1h"
  ssh_username = "root"
  ssh_password = "vagrant"
  boot_command = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /install.amd/vmlinuz console=ttyS0 ",
    "auto=true DEBIAN_FRONTEND=text TERM=dumb priority=critical keymap=en ",
    "url=http://{{.HTTPIP}}:{{.HTTPPort}}/debian-preseed.cfg --- <enter><wait>",
    "initrd /install.amd/initrd.gz<enter><wait>",
    "boot<enter>",
  ]
  efi_firmware_code = local.efi_firmware_code
  efi_firmware_vars = local.efi_firmware_vars
  qemuargs = [["-cpu", "host"], ["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  source "qemu.debian" {
    name = "debian13"
    output_directory = "output-${source.name}"
    iso_url = "https://cdimage.debian.org/cdimage/release/${local.debian13_version}/amd64/iso-cd/debian-${local.debian13_version}-amd64-netinst.iso"
    iso_checksum = "file:https://cdimage.debian.org/cdimage/release/${local.debian13_version}/amd64/iso-cd/SHA256SUMS"
    http_content = {
      "/debian-preseed.cfg" = templatefile("${path.root}/debian-preseed.cfg", { path = path, hostname = source.name })
    }
  }

  provisioner "shell" {
    inline = [
      "echo 'vagrant ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/vagrant",
      "chmod 0440 /etc/sudoers.d/vagrant"
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /home/vagrant/.ssh",
      "chmod 700 /home/vagrant/.ssh",
      "chown -R vagrant:vagrant /home/vagrant/.ssh",
    ]
  }

  provisioner "file" {
    source = "${path.root}/keys/vagrant.pub"
    destination = "/home/vagrant/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys",
      "chmod 644 /home/vagrant/.ssh/authorized_keys",
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
    ]
  }

  provisioner "file" {
    source = "${path.root}/keys/vagrant.pub"
    destination = "/root/.ssh/authorized_keys"
  }

  provisioner "shell" {
    inline = [
      "apt-get clean -y",
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
