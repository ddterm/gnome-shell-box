data "http" "opensusetumbleweed_iso_checksum" {
  url = "https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso.sha256"
}

local "opensusetumbleweed_iso_checksum_split" {
  expression = compact(split(" ", data.http.opensusetumbleweed_iso_checksum.body))
}

local "opensusetumbleweed_iso_checksum" {
  expression = trimspace(local.opensusetumbleweed_iso_checksum_split[0])
}

local "opensusetumbleweed_iso_name" {
  expression = trimspace(local.opensusetumbleweed_iso_checksum_split[1])
}

source "qemu" "opensusetumbleweed" {
  iso_url = "https://download.opensuse.org/tumbleweed/iso/${local.opensusetumbleweed_iso_name}"
  iso_checksum = "sha256:${local.opensusetumbleweed_iso_checksum}"
  vga = "virtio"
  cpus = 2
  memory = 2048
  headless = var.headless
  shutdown_command = "sudo /sbin/halt -h -p"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = "opensusetumbleweed", product = "openSUSE" })
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
