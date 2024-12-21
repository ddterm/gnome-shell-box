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
  ssh_handshake_attempts = 1000
  ssh_timeout = "2h"
  ssh_username = "root"
  ssh_password = "vagrant"
  boot_wait = "10s"
  boot_keygroup_interval = "1s"
  boot_command = [
    "<esc><wait><esc><wait><esc><wait><esc><wait><esc><wait><esc><wait>",
    "<esc><wait><esc><wait><esc><wait><esc><wait><esc><wait><esc><wait>",
    "/install.amd/vmlinuz console=ttyS0 ",
    "auto=true DEBIAN_FRONTEND=text TERM=dumb debconf/priority=critical ",
    "keyboard-configuration/xkb-keymap=en ",
    "initrd=/install.amd/initrd.gz --- ",
    "preseed/url=http://{{.HTTPIP}}:{{.HTTPPort}}/debian-preseed.cfg ",
    "<enter>"
  ]
  qemuargs = [["-serial", "stdio"]]
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
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/debian12"
      version = var.version
    }
  }
}
