source "qemu" "centos9s" {
  iso_url = "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-20240422.0-x86_64-boot.iso"
  iso_checksum = "file:https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-20240422.0-x86_64-boot.iso.SHA1SUM"
  vga = "virtio"
  cpus = 2
  memory = 2048
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/centos.ks" = templatefile("${path.root}/centos.ks", { path = path, hostname = "centos9s" })
  }
  ssh_handshake_attempts = 1000
  ssh_timeout = "2h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_wait = "10s"
  boot_keygroup_interval = "1s"
  boot_command = [
        "<tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/centos.ks inst.repo=https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/ vga=792 <enter><wait>"
  ]
  qemuargs = [["-serial", "stdio"], ["-cpu", "max"]]
}

build {
  sources = [
    "source.qemu.centos9s"
  ]

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-cloud" {
      box_tag = "mezinalexander/centos9s"
      version = var.version
    }
  }
}
