source "qemu" "alpine319" {
  iso_url = "https://mirrors.edge.kernel.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.0-x86_64.iso"
  iso_checksum = "file:https://mirrors.edge.kernel.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.0-x86_64.iso.sha256"
  vga = "virtio"
  cpus = 2
  memory = 2048
  headless = var.headless
  shutdown_command = "/sbin/poweroff"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/alpine-answer.sh" = templatefile("${path.root}/alpine-answer.sh", { path = path, hostname = "alpine319" })
    "/vagrant.pub" = file("${path.root}/keys/vagrant.pub")
  }
  ssh_handshake_attempts = 1000
  ssh_timeout = "10m"
  ssh_username = "root"
  ssh_private_key_file = "${path.root}/keys/vagrant"
  boot_wait = "1m"
  boot_keygroup_interval = "1s"
  boot_command = [
    "<enter><wait10>",
    "root<enter><wait10>",
    "setup-interfaces -a -r && ",
    "setup-sshd -k 'http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant.pub' openssh<enter>",
  ]
}

build {
  sources = [
    "source.qemu.alpine319"
  ]

  provisioner "shell" {
    inline = [
      "setup-alpine -e -f 'http://${build.PackerHTTPAddr}/alpine-answer.sh'",
    ]

    env = {
      "ERASE_DISKS" = "/dev/vda"
    }
  }

  provisioner "shell" {
    inline = ["reboot"]
    expect_disconnect = true
    pause_after = "1m"
  }

  provisioner "shell" {
    start_retry_timeout = "10m"
    inline = [
      "setup-xorg-base",
      "setup-desktop gnome",
      "apk add qemu-guest-agent spice-vdagent spice-webdavd rsync",
      "rc-update add qemu-guest-agent",
      "rc-update add spice-vdagentd",
      "rc-update add spice-webdavd",
      "usermod -p '${bcrypt("vagrant")}' vagrant",
      "usermod -p '${bcrypt("vagrant")}' root",
      "echo 'permit nopass :vagrant' >/etc/doas.d/vagrant.conf",
      "rm -rf /var/cache/apk/*",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-cloud" {
      box_tag = "mezinalexander/alpine319"
      version = var.version
    }
  }
}
