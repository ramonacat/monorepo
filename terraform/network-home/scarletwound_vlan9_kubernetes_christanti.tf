module "scarletwound-vlan9" {
  source = "../routeros-vlan"
  providers = {
    routeros = routeros.router-scarletwound
  }

  name      = "kubernetes-christanti"
  cidr      = "10.64.0.0/24"
  vlan_id   = 9
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  tagged_ports = [
    routeros_interface_bridge.scarletwound-bridge0.name,
    routeros_interface_ethernet.scarletwound-ether[4].name
  ]
  untagged_ports = [
  ]
}
