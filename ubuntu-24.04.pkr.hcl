source "qemu" "ubuntu2404" {
  iso_url = "https://releases.ubuntu.com/noble/ubuntu-24.04.1-desktop-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/noble/SHA256SUMS"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/ubuntu-autoinstall.yml" = templatefile("${path.root}/ubuntu-autoinstall.yml", { path = path, hostname = "ubuntu2404" })
  }
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
  qemuargs = [["-serial", "stdio"]]
}

build {
  sources = [
    "source.qemu.ubuntu2404"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get clean -y",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/ubuntu2404"
      version = local.version
    }
  }
}
