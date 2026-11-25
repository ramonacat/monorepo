module "scarletwound-vlan9" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name = "kubernetes-christanti"
  cidr = "10.64.0.0/28"
  # TODO this should probably be static only
  dhcp_ranges = ["10.64.0.8/29"]

  vlan_id   = 9
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    routeros_interface_ethernet.scarletwound-ether[3].name,
    routeros_interface_ethernet.scarletwound-ether[4].name
  ]
  untagged_ports = [
  ]
}

resource "routeros_ip_dhcp_server_lease" "scarletwound-depraysie" {
  provider    = routeros.router-scarletwound
  mac_address = "38:CA:84:BF:86:D7"
  address     = "10.64.0.10"
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan9" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan9.vlan_interface
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_interface_list_member" "scarletwound-internet-access-vlan9" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan9.vlan_interface
  list      = routeros_interface_list.scarletwound-internet-access.name
}
