source "qemu" "fedora39" {
  iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/39/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-39-1.5.iso"
  iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/39/Everything/x86_64/iso/Fedora-Everything-39-1.5-x86_64-CHECKSUM"
  vga = "virtio"
  cpus = 2
  memory = 2048
  headless = true
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  disk_detect_zeroes = "on"
  http_content = {
    "/fedora.ks" = templatefile("${path.root}/fedora.ks", { path = path, hostname = "fedora39" })
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
        "search --no-floppy --set=root -l 'Fedora-E-dvd-x86_64-39'<enter><wait>",
        "linux /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=Fedora-E-dvd-x86_64-39 rd.live.check ",
        "inst.text inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/fedora.ks<enter><wait>",
        "initrd /images/pxeboot/initrd.img<enter><wait10>",
        "boot<enter><wait>"
  ]
}

build {
  sources = [
    "source.qemu.fedora39"
  ]

  post-processors {
    post-processor "vagrant" {
      keep_input_artifact = true
      vagrantfile_template = "Vagrantfile"
    }
  }
}
