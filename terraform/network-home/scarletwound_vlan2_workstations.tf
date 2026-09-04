resource "routeros_interface_vlan" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan2"
  comment   = "workstations"
  vlan_id   = 2
}

resource "routeros_ip_dhcp_server_network" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound
  address  = "10.32.1.0/24"
  gateway  = "10.32.1.1"
  netmask  = 24
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan2" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan2.name
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_ip_pool" "scarletwound-workstations" {
  provider = routeros.router-scarletwound
  name     = "pool-workstations"
  ranges   = ["10.32.1.32-10.32.1.254"]
  comment  = "workstations/vlan2"
}

resource "routeros_dhcp_server" "scarletwound-workstations" {
  provider                  = routeros.router-scarletwound
  interface                 = routeros_interface_vlan.scarletwound-vlan2.name
  name                      = "dhcp-workstations"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
}

resource "routeros_bridge_vlan" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged   = [routeros_interface_bridge.scarletwound-bridge0.name, "ether5"]
  untagged = ["ether1", "ether3"]
  vlan_ids = [2]
}

resource "routeros_ip_address" "scarletwound-vlan2" {
  provider  = routeros.router-scarletwound
  address   = "10.32.1.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan2.name
  network   = "10.32.1.0"
}
