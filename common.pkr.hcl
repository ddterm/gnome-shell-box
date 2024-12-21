packer {
  required_plugins {
    qemu = {
      version = "= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = "= 1.1.5"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

variable "headless" {
  type = bool
  default = true
  description = "Build in headless mode"
}

variable "version" {
  type = string
  default = "0.0.0"
  description = "Box version for Vagrant Cloud"
}
