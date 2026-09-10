resource "routeros_interface_ethernet" "scarletwound-ether" {
  provider = routeros.router-scarletwound
  count    = 5

  factory_name    = "ether${count.index + 1}"
  name            = "ether${count.index + 1}"
  tx_flow_control = "on"
  rx_flow_control = "on"
  l2mtu           = 1598
}
