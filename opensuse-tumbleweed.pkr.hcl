source "qemu" "opensusetumbleweed" {
  iso_url = "https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Snapshot20240112-Media.iso"
  iso_checksum = "file:https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Snapshot20240112-Media.iso.sha256"
  vga = "virtio"
  cpus = 2
  memory = 2048
  headless = true
  shutdown_command = "sudo /sbin/halt -h -p"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = "opensusetumbleweed" })
  }
  ssh_handshake_attempts = 1000
  ssh_timeout = "90m"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_wait = "10s"
  boot_keygroup_interval = "1s"
  boot_command = [
    "<esc><enter><wait>",
    "linux netsetup=dhcp lang=en_US textmode=1 ssh=0 sshd=0 <wait>",
    "autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/opensuse.xml<wait>",
    "<enter><wait>"
  ]
}

build {
  sources = [
    "source.qemu.opensusetumbleweed"
  ]

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }
  }
}