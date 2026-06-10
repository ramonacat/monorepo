variable "name" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "placement_group_id" {
  type    = string
  default = null
}

variable "tailscale_tags" {
  type = list(string)
}

variable "dns_suffix" {
  type    = string
  default = ".devices"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "image" {
  type    = string
  default = "debian-13"
}
