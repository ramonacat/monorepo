module "scarletwound-vlan6" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name      = "iot"
  cidr      = "10.32.5.0/24"
  vlan_id   = 6
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    "ether5",
    "ether3",
  ]
  untagged_ports = [
    routeros_interface_wireless.scarletwound-wlan1-iot.name,
    routeros_interface_wireless.scarletwound-wlan2-iot.name,
  ]
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan6" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan6.vlan_interface
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_ipv6_address" "scarletwound-vlan6-ula" {
  provider  = routeros.router-scarletwound
  address   = "fd80:10e:18be:ca7::/64"
  interface = module.scarletwound-vlan6.vlan_interface
  advertise = true
}

resource "routeros_ip_dhcp_server_lease" "scarletwound-vlan6-homeassistant" {
  provider    = routeros.router-scarletwound
  mac_address = "74:E6:E2:2B:6D:E0"
  address     = "10.32.5.251"
}

moved {
  from = routeros_ip_pool.scarletwound-iot
  to   = module.scarletwound-vlan6.routeros_ip_pool.main
}

moved {
  from = routeros_interface_vlan.scarletwound-vlan6
  to   = module.scarletwound-vlan6.routeros_interface_vlan.main
}

moved {
  from = routeros_ip_dhcp_server_network.scarletwound-vlan6
  to   = module.scarletwound-vlan6.routeros_ip_dhcp_server_network.main
}

moved {
  from = routeros_dhcp_server.scarletwound-iot
  to   = module.scarletwound-vlan6.routeros_dhcp_server.main
}

moved {
  from = routeros_bridge_vlan.scarletwound-vlan6
  to   = module.scarletwound-vlan6.routeros_bridge_vlan.main
}

moved {
  from = routeros_ip_address.scarletwound-vlan6
  to   = module.scarletwound-vlan6.routeros_ip_address.main
}
