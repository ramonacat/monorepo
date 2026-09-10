module "scarletwound-vlan5" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name      = "low-privilege"
  cidr      = "10.32.4.0/24"
  vlan_id   = 5
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    routeros_interface_ethernet.scarletwound-ether[3].name,
  ]
  untagged_ports = [
    routeros_interface_wireless.scarletwound-wlan1-low-privilege.name,
    routeros_interface_wireless.scarletwound-wlan2-low-privilege.name,
  ]
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan5" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan5.vlan_interface
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_interface_list_member" "scarletwound-all-clients-vlan5" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan5.vlan_interface
  list      = routeros_interface_list.scarletwound-all-clients.name
}

resource "routeros_interface_list_member" "scarletwound-internet-access-vlan5" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan5.vlan_interface
  list      = routeros_interface_list.scarletwound-internet-access.name
}

moved {
  from = routeros_ip_pool.scarletwound-low-privilege
  to   = module.scarletwound-vlan5.routeros_ip_pool.main
}

moved {
  from = routeros_interface_vlan.scarletwound-vlan5
  to   = module.scarletwound-vlan5.routeros_interface_vlan.main
}

moved {
  from = routeros_ip_dhcp_server_network.scarletwound-vlan5
  to   = module.scarletwound-vlan5.routeros_ip_dhcp_server_network.main
}

moved {
  from = routeros_dhcp_server.scarletwound-low-privilege
  to   = module.scarletwound-vlan5.routeros_dhcp_server.main
}

moved {
  from = routeros_bridge_vlan.scarletwound-vlan5
  to   = module.scarletwound-vlan5.routeros_bridge_vlan.main
}

moved {
  from = routeros_ip_address.scarletwound-vlan5
  to   = module.scarletwound-vlan5.routeros_ip_address.main
}
