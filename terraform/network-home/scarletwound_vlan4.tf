resource "routeros_interface_vlan" "scarletwound-vlan4" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan4"
  comment   = "servers"
  vlan_id   = 4
}

resource "routeros_ip_dhcp_server_network" "scarletwound-vlan4" {
  provider = routeros.router-scarletwound
  address  = "10.32.3.0/24"
  gateway  = "10.32.3.1"
  netmask  = 24
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan4" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan4.name
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_ip_pool" "scarletwound-servers" {
  provider = routeros.router-scarletwound
  name     = "pool-servers"
  ranges   = ["10.32.3.32-10.32.3.254"]
  comment  = "servers/vlan4"
}

resource "routeros_dhcp_server" "scarletwound-servers" {
  provider                  = routeros.router-scarletwound
  interface                 = routeros_interface_vlan.scarletwound-vlan4.name
  name                      = "dhcp-servers"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
  address_pool              = routeros_ip_pool.scarletwound-servers.name
}

resource "routeros_bridge_vlan" "scarletwound-vlan4" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged   = [routeros_interface_bridge.scarletwound-bridge0.name, "ether5"]
  untagged = ["ether2"]
  vlan_ids = [4]
}

resource "routeros_ip_address" "scarletwound-vlan4" {
  provider  = routeros.router-scarletwound
  address   = "10.32.3.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan4.name
  network   = "10.32.3.0"
}

