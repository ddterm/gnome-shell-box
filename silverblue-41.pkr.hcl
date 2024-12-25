source "qemu" "silverblue41" {
  iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Silverblue/x86_64/iso/Fedora-Silverblue-ostree-x86_64-41-1.4.iso"
  iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/41/Silverblue/x86_64/iso/Fedora-Silverblue-41-1.4-x86_64-CHECKSUM"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/silverblue.ks" = templatefile("${path.root}/silverblue.ks", { path = path, hostname = "silverblue41", version = "41" })
  }
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_wait = "10s"
  boot_keygroup_interval = "1s"
  boot_command = [
        "c<wait10>",
        "set gfxpayload=keep<enter><wait>",
        "linux /images/pxeboot/vmlinuz console=ttyS0 inst.notmux inst.cmdline ",
        "inst.stage2=hd:LABEL=Fedora-SB-ostree-x86_64-41 ",
        "inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/silverblue.ks<enter><wait>",
        "initrd /images/pxeboot/initrd.img<enter><wait10>",
        "boot<enter>"
  ]
  qemuargs = [["-serial", "stdio"]]
}

build {
  sources = [
    "source.qemu.silverblue41"
  ]

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/silverblue41"
      version = local.version
    }
  }
}
