packer {
  required_plugins {
    qemu = {
      version = "=1.1.2"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = "= 1.1.5"
      source = "github.com/hashicorp/vagrant"
    }
    external = {
      version = "= 0.0.3"
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
}

locals {
  version = trimspace(data.external-raw.git-describe.result)
}
