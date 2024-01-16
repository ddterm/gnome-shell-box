source "qemu" "ubuntu2310" {
  iso_url = "https://releases.ubuntu.com/23.10.1/ubuntu-23.10.1-desktop-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/23.10.1/SHA256SUMS"
  vga = "virtio"
  machine_type = "q35"
  cpus = 2
  memory = 2048
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/ubuntu-autoinstall.yml" = templatefile("${path.root}/ubuntu-autoinstall.yml", { path = path, hostname = "ubuntu2310" })
  }
  ssh_handshake_attempts = 1000
  ssh_timeout = "90m"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_wait = "10s"
  boot_keygroup_interval = "1s"
  boot_command = [
    "<tab><wait><tab><wait><tab><wait><tab><wait><tab><wait><tab><wait>",
    "<tab><wait><tab><wait><tab><wait><tab><wait><tab><wait><tab><wait>",
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz autoinstall ",
    "cloud-config-url=\"http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu-autoinstall.yml\" --- <enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
}

build {
  sources = [
    "source.qemu.ubuntu2310"
  ]

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }
  }
}
