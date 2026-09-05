resource "routeros_interface_vlan" "scarletwound-vlan8" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan8"
  comment   = "untrusted"
  vlan_id   = 8
}

resource "routeros_ip_dhcp_server_network" "scarletwound-vlan8" {
  provider = routeros.router-scarletwound
  address  = "10.32.7.0/24"
  gateway  = "10.32.7.1"
  netmask  = 24
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan8" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan8.name
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_ip_pool" "scarletwound-untrusted" {
  provider = routeros.router-scarletwound
  name     = "pool-untrusted"
  ranges   = ["10.32.7.32-10.32.7.254"]
  comment  = "untrusted/vlan8"
}

resource "routeros_dhcp_server" "scarletwound-untrusted" {
  provider                  = routeros.router-scarletwound
  interface                 = routeros_interface_vlan.scarletwound-vlan8.name
  name                      = "pool-untrusted"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
  address_pool              = routeros_ip_pool.scarletwound-untrusted.name
}

resource "routeros_bridge_vlan" "scarletwound-vlan8" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    "ether5"
  ]
  untagged = [
  ]
  vlan_ids = [8]
}

resource "routeros_ip_address" "scarletwound-vlan8" {
  provider  = routeros.router-scarletwound
  address   = "10.32.7.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan8.name
  network   = "10.32.7.0"
}
