locals {
  # renovate: datasource=custom.html depName=alpine-virt-x86_64 extractVersion=(^|/)alpine-virt-(?<version>[0-9.]+)-x86_64\.iso$ registryUrl=https://mirrors.edge.kernel.org/alpine/v3.19/releases/x86_64/
  alpine319_version = "3.19.8"
  # renovate: datasource=custom.html depName=alpine-virt-x86_64 extractVersion=(^|/)alpine-virt-(?<version>[0-9.]+)-x86_64\.iso$ registryUrl=https://mirrors.edge.kernel.org/alpine/v3.20/releases/x86_64/
  alpine320_version = "3.20.7"
  # renovate: datasource=custom.html depName=alpine-virt-x86_64 extractVersion=(^|/)alpine-virt-(?<version>[0-9.]+)-x86_64\.iso$ registryUrl=https://mirrors.edge.kernel.org/alpine/v3.21/releases/x86_64/
  alpine321_version = "3.21.4"
  # renovate: datasource=custom.html depName=alpine-virt-x86_64 extractVersion=(^|/)alpine-virt-(?<version>[0-9.]+)-x86_64\.iso$ registryUrl=https://mirrors.edge.kernel.org/alpine/v3.22/releases/x86_64/
  alpine322_version = "3.22.1"
}

source "qemu" "alpine" {
  vga = "virtio"
  cpus = 2
  memory = 8192
  headless = var.headless
  qmp_enable = var.headless
  shutdown_command = "/sbin/poweroff"
  disk_discard = "unmap"
  ssh_username = "root"
  ssh_private_key_file = "${path.root}/keys/vagrant"
  boot_wait = "1m"
  boot_command = [
    "<enter><wait10>",
    "root<enter><wait10>",
    "setup-interfaces -a -r && ",
    "setup-sshd -k 'http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant.pub' openssh<enter>",
  ]
  efi_firmware_code = local.efi_firmware_code
  efi_firmware_vars = local.efi_firmware_vars
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  source "qemu.alpine" {
    name = "alpine319"
    output_directory = "output-${source.name}"
    iso_url = "https://mirrors.edge.kernel.org/alpine/v3.19/releases/x86_64/alpine-virt-${local.alpine319_version}-x86_64.iso"
    iso_checksum = "file:https://mirrors.edge.kernel.org/alpine/v3.19/releases/x86_64/alpine-virt-${local.alpine319_version}-x86_64.iso.sha256"
    http_content = {
      "/alpine-answer.sh" = templatefile("${path.root}/alpine-answer.sh", { path = path, hostname = source.name })
      "/vagrant.pub" = file("${path.root}/keys/vagrant.pub")
    }
  }

  source "qemu.alpine" {
    name = "alpine320"
    output_directory = "output-${source.name}"
    iso_url = "https://mirrors.edge.kernel.org/alpine/v3.20/releases/x86_64/alpine-virt-${local.alpine320_version}-x86_64.iso"
    iso_checksum = "file:https://mirrors.edge.kernel.org/alpine/v3.20/releases/x86_64/alpine-virt-${local.alpine320_version}-x86_64.iso.sha256"
    http_content = {
      "/alpine-answer.sh" = templatefile("${path.root}/alpine-answer.sh", { path = path, hostname = source.name })
      "/vagrant.pub" = file("${path.root}/keys/vagrant.pub")
    }
  }

  source "qemu.alpine" {
    name = "alpine321"
    output_directory = "output-${source.name}"
    iso_url = "https://mirrors.edge.kernel.org/alpine/v3.21/releases/x86_64/alpine-virt-${local.alpine321_version}-x86_64.iso"
    iso_checksum = "file:https://mirrors.edge.kernel.org/alpine/v3.21/releases/x86_64/alpine-virt-${local.alpine321_version}-x86_64.iso.sha256"
    http_content = {
      "/alpine-answer.sh" = templatefile("${path.root}/alpine-answer.sh", { path = path, hostname = source.name })
      "/vagrant.pub" = file("${path.root}/keys/vagrant.pub")
    }
  }

  source "qemu.alpine" {
    name = "alpine322"
    output_directory = "output-${source.name}"
    iso_url = "https://mirrors.edge.kernel.org/alpine/v3.22/releases/x86_64/alpine-virt-${local.alpine322_version}-x86_64.iso"
    iso_checksum = "file:https://mirrors.edge.kernel.org/alpine/v3.22/releases/x86_64/alpine-virt-${local.alpine322_version}-x86_64.iso.sha256"
    http_content = {
      "/alpine-answer.sh" = templatefile("${path.root}/alpine-answer.sh", { path = path, hostname = source.name })
      "/vagrant.pub" = file("${path.root}/keys/vagrant.pub")
    }
  }

  provisioner "shell" {
    inline = [
      "setup-alpine -e -f 'http://${build.PackerHTTPAddr}/alpine-answer.sh'",
    ]

    env = {
      "ERASE_DISKS" = "/dev/vda"
    }
  }

  provisioner "shell" {
    inline = [
      "apk add efibootmgr",
      "efibootmgr -c -d /dev/vda -p 1 -L alpine -l '\\EFI\\alpine\\grubx64.efi'",
    ]
  }

  provisioner "shell" {
    inline = ["reboot"]
    expect_disconnect = true
    pause_after = "1m"
  }

  provisioner "shell" {
    start_retry_timeout = "10m"
    inline = [
      "setup-xorg-base",
      "setup-desktop gnome",
      "apk add qemu-guest-agent spice-vdagent spice-webdavd rsync",
      "rc-update add qemu-guest-agent",
      "rc-update add spice-vdagentd",
      "rc-update add spice-webdavd",
      "usermod -p '${bcrypt("vagrant")}' vagrant",
      "usermod -p '${bcrypt("vagrant")}' root",
      "echo 'permit nopass :vagrant' >/etc/doas.d/vagrant.conf",
      "rm -rf /var/cache/apk/*",
      "fstrim -v /",
    ]
  }

  post-processors {
    post-processor "vagrant" {
      vagrantfile_template = "Vagrantfile"
      include = flatten([
        local.ovmf_include,
        "output-${source.name}/efivars.fd",
      ])
      compression_level = 9
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/${source.name}"
      version = local.version
    }
  }
}
