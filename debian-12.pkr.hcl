source "qemu" "debian12" {
  iso_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso"
  iso_checksum = "file:https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/debian-preseed.cfg" = templatefile("${path.root}/debian-preseed.cfg", { path = path, hostname = "debian12" })
  }
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
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  sources = [
    "source.qemu.debian12"
  ]

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
      box_tag = "gnome-shell-box/debian12"
      version = local.version
    }
  }
}
