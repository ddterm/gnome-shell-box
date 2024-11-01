source "qemu" "fedora41" {
  iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-41-1.4.iso"
  iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/41/Everything/x86_64/iso/Fedora-Everything-41-1.4-x86_64-CHECKSUM"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/fedora.ks" = templatefile("${path.root}/fedora.ks", { path = path, hostname = "fedora41" })
  }
  ssh_handshake_attempts = 1000
  ssh_timeout = "2h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_wait = "10s"
  boot_keygroup_interval = "1s"
  boot_command = [
        "c<wait>",
        "insmod all_video<enter><wait>",
        "set gfxpayload=keep<enter><wait>",
        "insmod increment<enter><wait>",
        "insmod xfs<enter><wait>",
        "insmod diskfilter<enter><wait>",
        "insmod mdraid1x<enter><wait>",
        "insmod fat<enter><wait>",
        "insmod blscfg<enter><wait>",
        "insmod gzio<enter><wait>",
        "insmod part_gpt<enter><wait>",
        "insmod ext2<enter><wait>",
        "insmod chain<enter><wait>",
        "search --no-floppy --set=root -l 'Fedora-E-dvd-x86_64-41'<enter><wait>",
        "linux /images/pxeboot/vmlinuz console=ttyS0 inst.notmux inst.cmdline ",
        "inst.stage2=hd:LABEL=Fedora-E-dvd-x86_64-41 ",
        "inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/fedora.ks<enter><wait>",
        "initrd /images/pxeboot/initrd.img<enter><wait10>",
        "boot<enter><wait>"
  ]
  qemuargs = [["-serial", "stdio"]]
}

build {
  sources = [
    "source.qemu.fedora41"
  ]

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/fedora41"
      version = var.version
    }
  }
}
