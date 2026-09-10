resource "routeros_interface_vlan" "everbleed-vlan2" {
  provider = routeros.router-everbleed

  interface = routeros_interface_bridge.everbleed-bridge0.name
  name      = "vlan2"
  comment   = "workstations"
  vlan_id   = 2
}

resource "routeros_interface_vlan" "everbleed-vlan3" {
  provider = routeros.router-everbleed

  interface = routeros_interface_bridge.everbleed-bridge0.name
  name      = "vlan3"
  comment   = "management"
  vlan_id   = 3
}

resource "routeros_interface_vlan" "everbleed-vlan4" {
  provider = routeros.router-everbleed

  interface = routeros_interface_bridge.everbleed-bridge0.name
  name      = "vlan4"
  comment   = "servers"
  vlan_id   = 4
}

resource "routeros_interface_vlan" "everbleed-vlan7" {
  provider = routeros.router-everbleed

  interface = routeros_interface_bridge.everbleed-bridge0.name
  name      = "vlan7"
  comment   = "isp"
  vlan_id   = 7
}

resource "routeros_bridge_vlan" "everbleed-vlan2" {
  provider = routeros.router-everbleed

  bridge = routeros_interface_bridge.everbleed-bridge0.name
  tagged = [
    routeros_interface_ethernet.everbleed-ether[0].name
  ]
  untagged = [
    routeros_interface_ethernet.everbleed-ether[2].name,
    routeros_interface_ethernet.everbleed-ether[3].name,
    routeros_interface_ethernet.everbleed-ether[5].name,
    routeros_interface_ethernet.everbleed-ether[6].name,
    routeros_interface_ethernet.everbleed-ether[7].name,
    routeros_interface_ethernet.everbleed-ether[19].name
  ]
  vlan_ids = [2]
}

resource "routeros_bridge_vlan" "everbleed-vlan3" {
  provider = routeros.router-everbleed

  bridge = routeros_interface_bridge.everbleed-bridge0.name
  tagged = [
    routeros_interface_bridge.everbleed-bridge0.name,
    routeros_interface_ethernet.everbleed-ether[0].name
  ]
  vlan_ids = [3]
}

resource "routeros_bridge_vlan" "everbleed-vlan4" {
  provider = routeros.router-everbleed

  bridge = routeros_interface_bridge.everbleed-bridge0.name
  tagged = [
    routeros_interface_ethernet.everbleed-ether[0].name
  ]
  vlan_ids = [4]
}

resource "routeros_bridge_vlan" "everbleed-vlan6" {
  provider = routeros.router-everbleed

  bridge = routeros_interface_bridge.everbleed-bridge0.name
  tagged = [
    routeros_interface_ethernet.everbleed-ether[0].name
  ]
  untagged = [
    routeros_interface_ethernet.everbleed-ether[4].name
  ]
  vlan_ids = [6]
}

resource "routeros_bridge_vlan" "everbleed-vlan7" {
  provider = routeros.router-everbleed

  bridge = routeros_interface_bridge.everbleed-bridge0.name
  tagged = [
    routeros_interface_ethernet.everbleed-ether[0].name
  ]
  untagged = [
    routeros_interface_ethernet.everbleed-ether[1].name
  ]
  vlan_ids = [7]
}

resource "routeros_bridge_vlan" "everbleed-vlan8" {
  provider = routeros.router-everbleed

  bridge = routeros_interface_bridge.everbleed-bridge0.name
  tagged = [
    routeros_interface_ethernet.everbleed-ether[0].name
  ]
  untagged = [
    routeros_interface_ethernet.everbleed-ether[2].name,
    routeros_interface_ethernet.everbleed-ether[6].name
  ]
  vlan_ids = [8]
}
