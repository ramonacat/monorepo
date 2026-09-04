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
  tagged   = [routeros_interface_bridge.scarletwound-bridge0.name, "ether5", "ether4"]
  vlan_ids = [3]
}

resource "routeros_ip_address" "scarletwound-vlan3" {
  provider  = routeros.router-scarletwound
  address   = "10.32.2.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan3.name
  network   = "10.32.2.0"
}
