resource "routeros_interface_ethernet" "everbleed-ether" {
  provider = routeros.router-everbleed
  count    = 24

  factory_name    = "ether${count.index + 1}"
  name            = "ether${count.index + 1}"
  tx_flow_control = "on"
  rx_flow_control = "on"
  l2mtu           = 1598
}

resource "routeros_interface_ethernet_switch_port_isolation" "everbleed-ether3-tv" {
  provider = routeros.router-everbleed

  name                = routeros_interface_ethernet.everbleed-ether[2].name
  forwarding_override = routeros_interface_ethernet.everbleed-ether[0].name
}

resource "routeros_interface_ethernet_switch_port_isolation" "everbleed-ether7-printer" {
  provider = routeros.router-everbleed

  name                = routeros_interface_ethernet.everbleed-ether[6].name
  forwarding_override = routeros_interface_ethernet.everbleed-ether[0].name
}
