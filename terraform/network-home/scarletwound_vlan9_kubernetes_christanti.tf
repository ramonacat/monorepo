module "scarletwound-vlan9" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name      = "kubernetes-christanti"
  cidr      = "10.64.0.0/24"
  vlan_id   = 2
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    routeros_interface_ethernet.scarletwound-ether[4].name
  ]
  untagged_ports = [
    routeros_interface_ethernet.scarletwound-ether[0].name
  ]
}

resource "routeros_interface_list_member" "scarletwound-lan-vlan2" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan2.vlan_interface
  list      = routeros_interface_list.scarletwound-lan.name
}

resource "routeros_interface_list_member" "scarletwound-internet-access-vlan2" {
  provider  = routeros.router-scarletwound
  interface = module.scarletwound-vlan2.vlan_interface
  list      = routeros_interface_list.scarletwound-internet-access.name
}
