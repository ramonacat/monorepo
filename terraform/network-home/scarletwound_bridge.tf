resource "routeros_interface_bridge" "scarletwound-bridge0" {
  provider = routeros.router-scarletwound

  name = "bridge0"
}

resource "routeros_interface_bridge_port" "scarletwound-ether1" {
  provider    = routeros.router-scarletwound
  interface   = "ether1"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 2
}

resource "routeros_interface_bridge_port" "scarletwound-ether2" {
  provider    = routeros.router-scarletwound
  interface   = "ether2"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 4
}

resource "routeros_interface_bridge_port" "scarletwound-ether3" {
  provider    = routeros.router-scarletwound
  interface   = "ether3"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 2
}

resource "routeros_interface_bridge_port" "scarletwound-ether5" {
  provider    = routeros.router-scarletwound
  interface   = "ether5"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-all"
  pvid        = 2
}

resource "routeros_bridge_port" "scarletwound-wlan1-iot" {
  provider    = routeros.router-scarletwound
  interface   = routeros_interface_wireless.scarletwound-wlan1-iot.name
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = routeros_interface_vlan.scarletwound-vlan6.vlan_id
}

resource "routeros_bridge_port" "scarletwound-wlan2-iot" {
  provider    = routeros.router-scarletwound
  interface   = routeros_interface_wireless.scarletwound-wlan2-iot.name
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = routeros_interface_vlan.scarletwound-vlan6.vlan_id
}

resource "routeros_bridge_port" "scarletwound-wlan1-low-privilege" {
  provider    = routeros.router-scarletwound
  interface   = routeros_interface_wireless.scarletwound-wlan1-low-privilege.name
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = routeros_interface_vlan.scarletwound-vlan5.vlan_id
}

resource "routeros_bridge_port" "scarletwound-wlan2-low-privilege" {
  provider    = routeros.router-scarletwound
  interface   = routeros_interface_wireless.scarletwound-wlan2-low-privilege.name
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = routeros_interface_vlan.scarletwound-vlan5.vlan_id
}

resource "routeros_interface_list_member" "scarletwound-lan-bridge0" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  list      = routeros_interface_list.scarletwound-lan.name
}

