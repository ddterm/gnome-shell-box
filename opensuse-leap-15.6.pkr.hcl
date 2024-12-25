source "qemu" "opensuseleap156" {
  iso_url = "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Build710.3-Media.iso"
  iso_checksum = "file:https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Build710.3-Media.iso.sha256"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo /sbin/halt -h -p"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = "opensuseleap156", product = "Leap" })
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
    "source.qemu.opensuseleap156"
  ]

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/opensuseleap156"
      version = local.version
    }
  }
}
