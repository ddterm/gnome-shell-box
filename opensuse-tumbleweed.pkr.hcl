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
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo /sbin/halt -h -p"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = "opensusetumbleweed", product = "openSUSE" })
  }
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
    "<esc><enter><wait>",
    "linux netsetup=dhcp lang=en_US textmode=1 ssh=0 sshd=0 linuxrc.log=/dev/ttyS0 <wait>",
    "autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/opensuse.xml<wait>",
    "<enter><wait>"
  ]
  qemuargs = [["-serial", "stdio"]]
}

build {
  sources = [
    "source.qemu.opensusetumbleweed"
  ]

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/opensusetumbleweed"
      version = local.version
    }
  }
}
