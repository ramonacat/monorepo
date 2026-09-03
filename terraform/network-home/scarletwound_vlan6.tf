resource "routeros_interface_vlan" "scarletwound-vlan6" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan6"
  comment   = "iot"
  vlan_id   = 6
}

resource "routeros_ip_dhcp_server_network" "scarletwound-vlan6" {
  provider = routeros.router-scarletwound
  address  = "10.32.5.0/24"
  gateway  = "10.32.5.1"
  netmask  = 24
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan6" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan6.name
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_ip_pool" "scarletwound-iot" {
  provider = routeros.router-scarletwound
  name     = "pool-iot"
  ranges   = ["10.32.5.32-10.32.5.254"]
  comment  = "iot/vlan6"
}

resource "routeros_dhcp_server" "scarletwound-iot" {
  provider                  = routeros.router-scarletwound
  interface                 = routeros_interface_vlan.scarletwound-vlan6.name
  name                      = "pool-iot"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
  address_pool              = routeros_ip_pool.scarletwound-iot.name
}

resource "routeros_bridge_vlan" "scarletwound-vlan6" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged = [
    routeros_interface_bridge.scarletwound-bridge0.name,
  ]
  untagged = [
    routeros_interface_wireless.scarletwound-wlan1-iot.name,
    routeros_interface_wireless.scarletwound-wlan2-iot.name,
  ]
  vlan_ids = [6]
}

resource "routeros_ip_address" "scarletwound-vlan6" {
  provider  = routeros.router-scarletwound
  address   = "10.32.5.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan6.name
  network   = "10.32.5.0"
}

