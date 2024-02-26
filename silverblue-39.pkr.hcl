source "qemu" "silverblue39" {
  iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/39/Silverblue/x86_64/iso/Fedora-Silverblue-ostree-x86_64-39-1.5.iso"
  iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/39/Silverblue/x86_64/iso/Fedora-Silverblue-39-1.5-x86_64-CHECKSUM"
  vga = "virtio"
  cpus = 2
  memory = 2048
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/silverblue.ks" = templatefile("${path.root}/silverblue.ks", { path = path, hostname = "silverblue39", version = "39" })
  }
  ssh_handshake_attempts = 1000
  ssh_timeout = "90m"
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
        "search --no-floppy --set=root -l 'Fedora-SB-ostree-x86_64-39'<enter><wait>",
        "linux /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=Fedora-SB-ostree-x86_64-39 rd.live.check ",
        "inst.text inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/silverblue.ks<enter><wait>",
        "initrd /images/pxeboot/initrd.img<enter><wait10>",
        "boot<enter><wait>"
  ]
}

build {
  sources = [
    "source.qemu.silverblue39"
  ]

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }

    post-processor "vagrant-cloud" {
      box_tag = "mezinalexander/silverblue39"
      version = var.version
    }
  }
}
