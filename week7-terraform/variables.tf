variable "vm_name" {
  description = "Name of the cPouta VM"
  type        = string
}

variable "network_name" {
  description = "cPouta network name"
  type        = string
}

variable "image_name" {
  description = "Linux image name"
  type        = string
}

variable "flavor_name" {
  description = "cPouta VM flavor"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to access SSH"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR, e.g. 203.0.113.45/32."
  }
}

variable "ssh_key_name" {
  description = "Name of the OpenStack key pair"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key"
  type        = string
}

variable "external_network_name" {
  description = "Name of the external network used for the floating IP"
  type        = string
}