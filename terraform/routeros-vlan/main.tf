terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

locals {
  prefix_length = replace(var.cidr, "/^.*\\//", "")
  bridge        = coalesce(var.bridge, var.interface)
}

resource "routeros_interface_vlan" "main" {
  interface = var.interface
  name      = "vlan${var.vlan_id}"
  comment   = var.name
  vlan_id   = var.vlan_id
}

resource "routeros_ip_dhcp_server_network" "main" {
  address    = var.cidr
  gateway    = cidrhost(var.cidr, 1)
  dns_server = [cidrhost(var.cidr, 1)]
  netmask    = local.prefix_length
}

resource "routeros_ip_pool" "main" {
  name = "pool-${var.name}"
  # TODO this will be wrong for subnets that aren't /24
  ranges  = ["${cidrhost(var.cidr, 32)}-${cidrhost(var.cidr, 254)}"]
  comment = "${var.name}/vlan${var.vlan_id}"
}

resource "routeros_dhcp_server" "main" {
  interface                 = routeros_interface_vlan.main.name
  name                      = "dhcp-${var.name}"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
}

resource "routeros_bridge_vlan" "main" {
  bridge   = local.bridge
  tagged   = var.tagged_ports
  untagged = var.untagged_ports
  vlan_ids = [var.vlan_id]
}

resource "routeros_ip_address" "main" {
  address   = "${cidrhost(var.cidr, 1)}/${local.prefix_length}"
  interface = routeros_interface_vlan.main.name
  network   = cidrhost(var.cidr, 0)
}
