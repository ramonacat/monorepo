resource "routeros_routing_ospf_instance" "scarletwound-main" {
  provider = routeros.router-scarletwound

  name = "main"
  # TODO this should come from the ras ipam provider, once it actually exists
  router_id = "10.255.232.1"
}

resource "routeros_routing_ospf_area" "scarletwound-backbone" {
  provider = routeros.router-scarletwound

  name     = "backbone"
  instance = routeros_routing_ospf_instance.scarletwound-main.name
  area_id  = "0.0.0.0"
}

resource "routeros_routing_ospf_interface_template" "scarletwound-local-network" {
  provider = routeros.router-scarletwound

  area    = routeros_routing_ospf_area.scarletwound-backbone.name
  use_bfd = true
  cost    = 1000
  # TODO this should come from the ras ipam provider
  networks = ["10.32.0.0/14"]
}

resource "routeros_routing_ospf_interface_template" "scarletwound-tunnels" {
  provider = routeros.router-scarletwound

  area    = routeros_routing_ospf_area.scarletwound-backbone.name
  use_bfd = true
  cost    = 10000
  # TODO this should come from the ras ipam provider
  networks = ["10.255.240.0/20"]
  type     = "ptp"
}

resource "routeros_routing_bfd_configuration" "scarletwound-main" {
  provider = routeros.router-scarletwound

  disabled = false
}
