resource "routeros_interface_vlan" "scarletwound-vlan7" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan7"
  comment   = "ISP"
  vlan_id   = 7
}

resource "routeros_bridge_vlan" "scarletwound-vlan7" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged   = [routeros_interface_bridge.scarletwound-bridge0.name, "ether5"]
  vlan_ids = [7]
}

resource "routeros_ip_dhcp_client" "scarletwound-vlan7" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan7.name
}

resource "routeros_interface_list_member" "scarletwound-wan-vlan7" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan7.name
  list      = routeros_interface_list.scarletwound-wan.name
}

