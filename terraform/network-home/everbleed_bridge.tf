resource "routeros_interface_bridge" "everbleed-bridge0" {
  provider = routeros.router-everbleed

  name = "bridgeLocal"
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether1" {
  provider = routeros.router-everbleed

  interface = "ether1"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan2.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether2" {
  provider = routeros.router-everbleed

  interface = "ether2"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = routeros_interface_vlan.scarletwound-vlan7.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether3" {
  provider = routeros.router-everbleed

  interface = "ether3"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan8.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether4" {
  provider = routeros.router-everbleed

  interface = "ether4"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan2.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether5" {
  provider = routeros.router-everbleed

  interface = "ether5"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan6.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether6" {
  provider = routeros.router-everbleed

  interface = "ether6"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan2.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether7" {
  provider = routeros.router-everbleed

  interface = "ether7"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan8.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether8" {
  provider = routeros.router-everbleed

  interface = "ether8"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan2.vlan_id
}

resource "routeros_interface_bridge_port" "everbleed-bridge0-ether20" {
  provider = routeros.router-everbleed

  interface = "ether20"
  bridge    = routeros_interface_bridge.everbleed-bridge0.name
  pvid      = module.scarletwound-vlan2.vlan_id
}
