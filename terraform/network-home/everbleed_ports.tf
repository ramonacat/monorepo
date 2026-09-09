resource "routeros_interface_ethernet" "everbleed-ether" {
  provider = routeros.router-everbleed
  count = 24

  factory_name = "ether${count.index+1}"
  name = "ether${count.index+1}"
  tx_flow_control = "on"
  rx_flow_control = "on"
  l2mtu = 1598
}
