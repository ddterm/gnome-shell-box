source "qemu" "ubuntu2204" {
  iso_url = "https://releases.ubuntu.com/jammy/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/jammy/SHA256SUMS"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = true
  disk_discard = "unmap"
  http_content = {
    "/ubuntu-22.04-autoinstall.yml" = templatefile("${path.root}/ubuntu-22.04-autoinstall.yml", { path = path, hostname = "ubuntu2204" })
  }
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz autoinstall console=ttyS0 ",
    "cloud-config-url=\"http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu-22.04-autoinstall.yml\" --- <enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  sources = [
    "source.qemu.ubuntu2204"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get clean -y",
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
      box_tag = "gnome-shell-box/ubuntu2204"
      version = local.version
    }
  }
}
