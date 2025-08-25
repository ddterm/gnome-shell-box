packer {
  required_plugins {
    qemu = {
      # renovate: datasource=github-tags depName=hashicorp/packer-plugin-qemu versioning=hashicorp
      version = "=1.1.4"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      # renovate: datasource=github-tags depName=hashicorp/packer-plugin-vagrant versioning=hashicorp
      version = "=1.1.6"
      source = "github.com/hashicorp/vagrant"
    }
    external = {
      # renovate: datasource=github-tags depName=joomcode/packer-plugin-external versioning=hashicorp
      version = "=0.0.3"
      source  = "github.com/joomcode/external"
    }
  }
}

variable "headless" {
  type = bool
  default = true
  description = "Build in headless mode"
}

variable "machine_type" {
  type = string
  default = "pc-q35-8.2"
  description = "QEMU machine type"
}

variable "log_dir" {
  type = string
  default = "logs"
  description = "Log download directory (on the host)"
}

data "external-raw" "git-describe" {
  program = ["git", "describe", "--tags"]
  working_dir = path.root
}

locals {
  version = trimspace(data.external-raw.git-describe.result)
  efi_firmware_code = "${path.root}/ovmf/OVMF_CODE.4m.fd"
  efi_firmware_vars = "${path.root}/ovmf/OVMF_VARS.4m.fd"
}

local "ovmf_include" {
  expression = [
    local.efi_firmware_code,
    "${path.root}/ovmf/edk2.License.txt",
    "${path.root}/ovmf/OvmfPkg.License.txt",
  ]
}
