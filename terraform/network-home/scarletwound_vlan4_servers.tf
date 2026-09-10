module "scarletwound-vlan4" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name      = "servers"
  cidr      = "10.32.3.0/24"
  vlan_id   = 4
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    routeros_interface_ethernet.scarletwound-ether[2].name,
    routeros_interface_ethernet.scarletwound-ether[4].name
  ]
  untagged_ports = [
    routeros_interface_ethernet.scarletwound-ether[1].name,
  ]
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan4" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan4.vlan_interface
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_interface_list_member" "scarletwound-internet-access-vlan4" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan4.vlan_interface
  list      = routeros_interface_list.scarletwound-internet-access.name
}

resource "routeros_ip_dhcp_server_lease" "scarletwound-hallewell" {
  provider    = routeros.router-scarletwound
  mac_address = "70:85:C2:A8:65:04"
  address     = "10.32.3.254"
}

resource "routeros_ip_dhcp_server_lease" "scarletwound-pikvm" {
  provider    = routeros.router-scarletwound
  mac_address = "E4:5F:01:23:13:40"
  address     = "10.32.3.253"
}

resource "routeros_ipv6_address" "scarletwound-vlan4-ula" {
  provider  = routeros.router-scarletwound
  address   = "fd62:821e:8341:ca7::/64"
  interface = module.scarletwound-vlan4.vlan_interface
  advertise = true
}

moved {
  from = routeros_ip_pool.scarletwound-servers
  to   = module.scarletwound-vlan4.routeros_ip_pool.main
}

moved {
  from = routeros_interface_vlan.scarletwound-vlan4
  to   = module.scarletwound-vlan4.routeros_interface_vlan.main
}

moved {
  from = routeros_ip_dhcp_server_network.scarletwound-vlan4
  to   = module.scarletwound-vlan4.routeros_ip_dhcp_server_network.main
}

moved {
  from = routeros_dhcp_server.scarletwound-servers
  to   = module.scarletwound-vlan4.routeros_dhcp_server.main
}

moved {
  from = routeros_bridge_vlan.scarletwound-vlan4
  to   = module.scarletwound-vlan4.routeros_bridge_vlan.main
}

moved {
  from = routeros_ip_address.scarletwound-vlan4
  to   = module.scarletwound-vlan4.routeros_ip_address.main
}
