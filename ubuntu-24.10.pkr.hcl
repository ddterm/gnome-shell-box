source "qemu" "ubuntu2410" {
  iso_url = "https://releases.ubuntu.com/24.10/ubuntu-24.10-desktop-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/24.10/SHA256SUMS"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = var.headless
  disk_discard = "unmap"
  http_content = {
    "/ubuntu-autoinstall.yml" = templatefile("${path.root}/ubuntu-autoinstall.yml", { path = path, hostname = "ubuntu2410" })
  }
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
    "c<wait10>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz autoinstall console=ttyS0 ",
    "cloud-config-url=\"http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu-autoinstall.yml\" --- <enter><wait>",
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
    "source.qemu.ubuntu2410"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get clean -y",
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
      box_tag = "gnome-shell-box/ubuntu2410"
      version = local.version
    }
  }
}
