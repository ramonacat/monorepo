resource "routeros_queue_tree" "scarletwound-vlan4" {
  provider = routeros.router-scarletwound
  name     = "vlan4"
  parent   = module.scarletwound-vlan4.vlan_interface
  priority = 6
}

resource "routeros_queue_tree" "scarletwound-vlan3" {
  provider = routeros.router-scarletwound
  name     = "vlan3"
  parent   = routeros_interface_vlan.scarletwound-vlan3.name
}

resource "routeros_queue_tree" "scarletwound-vlan7" {
  provider = routeros.router-scarletwound
  name     = "vlan7"
  parent   = routeros_interface_vlan.scarletwound-vlan7.name
}
