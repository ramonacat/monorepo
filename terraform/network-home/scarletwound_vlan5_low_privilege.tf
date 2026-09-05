resource "routeros_interface_vlan" "scarletwound-vlan5" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan5"
  comment   = "low privilege"
  vlan_id   = 5
}

resource "routeros_ip_dhcp_server_network" "scarletwound-vlan5" {
  provider = routeros.router-scarletwound
  address  = "10.32.4.0/24"
  gateway  = "10.32.4.1"
  netmask  = 24
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan5" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan5.name
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_ip_pool" "scarletwound-low-privilege" {
  provider = routeros.router-scarletwound
  name     = "pool-low-privilege"
  ranges   = ["10.32.4.32-10.32.4.254"]
  comment  = "low-privilege/vlan5"
}

resource "routeros_dhcp_server" "scarletwound-low-privilege" {
  provider                  = routeros.router-scarletwound
  interface                 = routeros_interface_vlan.scarletwound-vlan5.name
  name                      = "dhcp-low-privilege"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
  address_pool              = routeros_ip_pool.scarletwound-low-privilege.name
}

resource "routeros_bridge_vlan" "scarletwound-vlan5" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    "ether4"
  ]
  untagged = [
    routeros_interface_wireless.scarletwound-wlan1-low-privilege.name,
    routeros_interface_wireless.scarletwound-wlan2-low-privilege.name,
  ]
  vlan_ids = [5]
}

resource "routeros_ip_address" "scarletwound-vlan5" {
  provider  = routeros.router-scarletwound
  address   = "10.32.4.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan5.name
  network   = "10.32.4.0"
}

