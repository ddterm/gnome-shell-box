source "qemu" "alpine320" {
  iso_url = "https://mirrors.edge.kernel.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.7-x86_64.iso"
  iso_checksum = "file:https://mirrors.edge.kernel.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.7-x86_64.iso.sha256"
  vga = "virtio"
  cpus = 2
  memory = 4096
  headless = var.headless
  shutdown_command = "/sbin/poweroff"
  qmp_enable = var.headless
  disk_discard = "unmap"
  http_content = {
    "/alpine-answer.sh" = templatefile("${path.root}/alpine-answer.sh", { path = path, hostname = "alpine320" })
    "/vagrant.pub" = file("${path.root}/keys/vagrant.pub")
  }
  ssh_username = "root"
  ssh_private_key_file = "${path.root}/keys/vagrant"
  boot_wait = "1m"
  boot_command = [
    "<enter><wait10>",
    "root<enter><wait10>",
    "setup-interfaces -a -r && ",
    "setup-sshd -k 'http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant.pub' openssh<enter>",
  ]
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
  qemuargs = [["-serial", "stdio"]]
  machine_type = var.machine_type
}

build {
  sources = [
    "source.qemu.alpine320"
  ]

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
      include = [
        "${path.root}/ovmf/OVMF_CODE.4m.fd",
        "${path.root}/output-${source.name}/efivars.fd",
        "${path.root}/ovmf/edk2.License.txt",
        "${path.root}/ovmf/OvmfPkg.License.txt",
      ]
      compression_level = 9
    }

    post-processor "vagrant-registry" {
      box_tag = "gnome-shell-box/alpine320"
      version = local.version
    }
  }
}
