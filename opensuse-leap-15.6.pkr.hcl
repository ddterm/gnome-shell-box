source "qemu" "opensuseleap156" {
  iso_url = "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Build710.3-Media.iso"
  iso_checksum = "file:https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Build710.3-Media.iso.sha256"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo /sbin/halt -h -p"
  qmp_enable = var.headless
  disk_discard = "unmap"
  http_content = {
    "/opensuse.xml" = templatefile("${path.root}/opensuse.xml", { path = path, hostname = "opensuseleap156", product = "Leap" })
  }
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /boot/x86_64/loader/linux netsetup=dhcp lang=en_US textmode=1 ssh=0 sshd=0 linuxrc.log=/dev/ttyS0 <wait>",
    "autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/opensuse.xml<enter><wait>",
    "initrd /boot/x86_64/loader/initrd<enter><wait>",
    "boot<enter>"
  ]
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  sources = [
    "source.qemu.opensuseleap156"
  ]

  provisioner "shell" {
    inline = [
      "sudo fstrim -av --quiet-unsupported",
    ]
  }

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
      box_tag = "gnome-shell-box/opensuseleap156"
      version = local.version
    }
  }
}
