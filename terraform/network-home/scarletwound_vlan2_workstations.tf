module "scarletwound-vlan2" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name      = "workstations"
  cidr      = "10.32.1.0/24"
  vlan_id   = 2
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    "ether5"
  ]
  untagged_ports = ["ether1"]
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan2" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan2.vlan_interface
  list      = routeros_interface_list.scarletwound-lan.name
}

moved {
  from = routeros_ip_pool.scarletwound-workstations
  to   = module.scarletwound-vlan2.routeros_ip_pool.main
}

moved {
  from = routeros_interface_vlan.scarletwound-vlan2
  to   = module.scarletwound-vlan2.routeros_interface_vlan.main
}

moved {
  from = routeros_ip_dhcp_server_network.scarletwound-vlan2
  to   = module.scarletwound-vlan2.routeros_ip_dhcp_server_network.main
}

moved {
  from = routeros_dhcp_server.scarletwound-workstations
  to   = module.scarletwound-vlan2.routeros_dhcp_server.main
}

moved {
  from = routeros_bridge_vlan.scarletwound-vlan2
  to   = module.scarletwound-vlan2.routeros_bridge_vlan.main
}

moved {
  from = routeros_ip_address.scarletwound-vlan2
  to   = module.scarletwound-vlan2.routeros_ip_address.main
}
