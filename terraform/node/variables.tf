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

variable "firewall_ids" {
  type = list(string)
}

variable "vault_pki" {
  type = string
}

variable "vault_role" {
  type = string
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

variable "skip_instance_id" {
  type    = bool
  default = false
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "before_node_update" {
  type    = object({ command : string, arguments : list(string) })
  default = { command = "true", arguments = [] }
}

variable "after_node_update" {
  type    = object({ command : string, arguments : list(string) })
  default = { command = "true", arguments = [] }
}
