locals {
  # renovate: datasource=custom.html depName=Fedora-Everything-netinst-x86_64 versioning=regex:^(?<major>[0-9]+)-(?<minor>[0-9]+)\.(?<patch>[0-9]+)$ extractVersion=(^|/)Fedora-Everything-netinst-x86_64-(?<version>[0-9.-]+)\.iso$ registryUrl=https://download.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/iso/
  fedora42_version = "42-1.1"
}

source "qemu" "fedora42" {
  iso_url = "https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-${local.fedora42_version}.iso"
  iso_checksum = "file:https://dl.fedoraproject.org/pub/fedora/linux/releases/42/Everything/x86_64/iso/Fedora-Everything-${local.fedora42_version}-x86_64-CHECKSUM"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "sudo shutdown -P now"
  qmp_enable = var.headless
  disk_discard = "unmap"
  http_content = {
    "/fedora.ks" = templatefile("${path.root}/fedora.ks", { path = path, hostname = "fedora42" })
  }
  ssh_timeout = "1h"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  boot_command = [
        "c<wait10>",
        "set gfxpayload=keep<enter><wait>",
        "linux /images/pxeboot/vmlinuz console=ttyS0 inst.notmux inst.cmdline ",
        "inst.stage2=hd:LABEL=Fedora-E-dvd-x86_64-42 ",
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
    "source.qemu.fedora42"
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
      compression_level = 9
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/fedora42"
      version = local.version
    }
  }
}
