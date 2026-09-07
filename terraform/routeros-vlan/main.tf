terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

locals {
  prefix_length = replace(vars.cidr, "/^.*\\//", "")
}

resource "routeros_interface_vlan" "main" {
  interface = vars.interface
  name      = "vlan${vars.vlan_id}"
  comment   = vars.name
  vlan_id   = vars.vlan_id
}

resource "routeros_ip_dhcp_server_network" "main" {
  address = vars.cidr
  gateway = cidrhost(vars.cidr, 1)
  dns_server = [cidrhost(vars.cidr, 1)]
  netmask = locals.prefix_length
}

resource "routeros_ip_pool" "main" {
  name = "pool-${vars.name}"
  # TODO this will be wrong for subnets that aren't /24
  ranges  = ["${cidrhost(vars.cidr, 32)}-${cidrhost(vars.cidr, 254)}"]
  comment = "${vars.name}/vlan${vars.vlan_id}"
}

resource "routeros_dhcp_server" "main" {
  interface                 = vars.interface
  name                      = "dhcp-${vars.name}"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
}

resource "routeros_bridge_vlan" "main" {
  bridge   = vars.bridge
  tagged   = vars.tagged_ports
  untagged = vars.untagged_ports
  vlan_ids = [vars.vlan_id]
}

resource "routeros_ip_address" "scarletwound-vlan2" {
  address   = "${cidrhost(vars.cidr, 1)}/${locals.prefix_length}"
  interface = vars.interface
  network   = cidrhost(vars.cidr, 0)
}
