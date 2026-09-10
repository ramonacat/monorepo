resource "routeros_interface_vlan" "scarletwound-vlan3" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan3"
  comment   = "management"
  vlan_id   = 3
}

resource "routeros_bridge_vlan" "scarletwound-vlan3" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    routeros_interface_ethernet.scarletwound-ether[4].name,
    routeros_interface_ethernet.scarletwound-ether[3].name,
    routeros_interface_ethernet.scarletwound-ether[2].name
  ]
  vlan_ids = [3]
}

locals {
  scarletwound_vlan3_ip = replace(routeros_ip_address.scarletwound-vlan3.address, "/\\/\\d+$/", "")
}

resource "routeros_ip_address" "scarletwound-vlan3" {
  provider  = routeros.router-scarletwound
  address   = "10.32.2.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan3.name
  network   = "10.32.2.0"
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan3" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan3.name
  list      = routeros_interface_list.scarletwound-lan.name
}
