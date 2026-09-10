module "scarletwound-vlan8" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name      = "untrusted"
  cidr      = "10.32.7.0/24"
  vlan_id   = 8
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    routeros_interface_ethernet.scarletwound-ether[4].name
  ]
  untagged_ports = []
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan8" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan8.vlan_interface
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_ip_dhcp_server_lease" "scarletwound-tv" {
  provider    = routeros.router-scarletwound
  mac_address = "AC:5A:F0:A1:6D:65"
  address     = "10.32.7.253"
}

resource "routeros_ip_dhcp_server_lease" "scarletwound-printer" {
  provider    = routeros.router-scarletwound
  mac_address = "94:DD:F8:90:D3:D1"
  address     = "10.32.7.254"
}

moved {
  from = routeros_ip_pool.scarletwound-untrusted
  to   = module.scarletwound-vlan8.routeros_ip_pool.main
}

moved {
  from = routeros_interface_vlan.scarletwound-vlan8
  to   = module.scarletwound-vlan8.routeros_interface_vlan.main
}

moved {
  from = routeros_ip_dhcp_server_network.scarletwound-vlan8
  to   = module.scarletwound-vlan8.routeros_ip_dhcp_server_network.main
}

moved {
  from = routeros_dhcp_server.scarletwound-untrusted
  to   = module.scarletwound-vlan8.routeros_dhcp_server.main
}

moved {
  from = routeros_bridge_vlan.scarletwound-vlan8
  to   = module.scarletwound-vlan8.routeros_bridge_vlan.main
}

moved {
  from = routeros_ip_address.scarletwound-vlan8
  to   = module.scarletwound-vlan8.routeros_ip_address.main
}
