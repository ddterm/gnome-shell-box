source "qemu" "debian12" {
  iso_url = "https://cdimage.debian.org/cdimage/release/12.5.0/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
  iso_checksum = "file:https://cdimage.debian.org/cdimage/release/12.5.0/amd64/iso-cd/SHA512SUMS"
  vga = "virtio"
  cpus = 2
  memory = 2048
  headless = var.headless
  shutdown_command = "shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/debian-preseed.cfg" = templatefile("${path.root}/debian-preseed.cfg", { path = path, hostname = "debian12" })
  }
  ssh_handshake_attempts = 1000
  ssh_timeout = "90m"
  ssh_username = "root"
  ssh_password = "vagrant"
  boot_wait = "10s"
  boot_keygroup_interval = "1s"
  boot_command = [
    "<esc><wait><esc><wait><esc><wait><esc><wait><esc><wait><esc><wait>",
    "<esc><wait><esc><wait><esc><wait><esc><wait><esc><wait><esc><wait>",
    "/install.amd/vmlinuz auto=true keyboard-configuration/xkb-keymap=en debconf/priority=critical initrd=/install.amd/initrd.gz --- ",
    "preseed/url=http://{{.HTTPIP}}:{{.HTTPPort}}/debian-preseed.cfg ",
    "<enter>"
  ]
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
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-cloud" {
      box_tag = "mezinalexander/debian12"
      box_checksum = "sha1:{$checksum}"
      version = var.version
    }
  }
}
