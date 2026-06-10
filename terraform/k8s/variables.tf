variable "dns_zone_name" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "control_plane_nodes" {
  type = map(object({ tailscale_tags : set(string) }))
}
