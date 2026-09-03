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

resource "routeros_interface_list_member" "scarletwound-lan-bridge0" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  list      = routeros_interface_list.scarletwound-lan.name
}

