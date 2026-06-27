variable "name" {
  type = string
}

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

variable "nodes" {
  type = map(object({ tailscale_tags : set(string), private_ipv4 : string }))
}

variable "subnet_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "firewall_ids" {
  type = list(string)
}

variable "pod_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "dnsimple_token" {
  type      = string
  sensitive = true
}

variable "create_grafana_dashboards" {
  type    = bool
  default = true
}

variable "discord_webhook" {
  type      = string
  sensitive = true
}
