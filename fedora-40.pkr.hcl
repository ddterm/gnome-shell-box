source "qemu" "fedora40" {
  iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-40-1.14.iso"
  iso_checksum = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/40/Everything/x86_64/iso/Fedora-Everything-40-1.14-x86_64-CHECKSUM"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = var.headless
  disk_discard = "unmap"
  http_content = {
    "/fedora.ks" = templatefile("${path.root}/fedora.ks", { path = path, hostname = "fedora40" })
  }
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
        "c<wait10>",
        "set gfxpayload=keep<enter><wait>",
        "linux /images/pxeboot/vmlinuz console=ttyS0 inst.notmux inst.cmdline ",
        "inst.stage2=hd:LABEL=Fedora-E-dvd-x86_64-40 ",
        "inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/fedora.ks<enter><wait>",
        "initrd /images/pxeboot/initrd.img<enter><wait10>",
        "boot<enter>"
  ]
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  sources = [
    "source.qemu.fedora40"
  ]

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
      include = [
        "${path.root}/ovmf/OVMF_CODE.4m.fd",
        "${path.root}/output-${source.name}/efivars.fd",
        "${path.root}/ovmf/edk2.License.txt",
        "${path.root}/ovmf/OvmfPkg.License.txt",
      ]
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/fedora40"
      version = local.version
    }
  }
}
