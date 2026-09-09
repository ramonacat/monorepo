module "scarletwound-firewall" {
  source = "../routeros-firewall"
  providers = {
    routeros = routeros.router-scarletwound
  }
  rules = [
    { chain = "forward", action = "fasttrack-connection", connection_state = "established,related" },
    { chain = "forward", action = "accept", connection_state = "established,related,untracked" },
    { chain = "input", action = "accept", connection_state = "established,related,untracked" },
    { chain = "input", action = "drop", connection_state = "invalid", },
    { chain = "input", action = "accept", protocol = "icmp" },
    { chain = "input", action = "accept", dst_address = "127.0.0.1", },
    { chain = "input", action = "drop", in_interface_list = "!${routeros_interface_list.scarletwound-lan.name}" },
    { chain = "forward", action = "drop", connection_state = "invalid" },
    { chain = "forward", action = "drop", connection_nat_state = "!dstnat", connection_state = "new", in_interface_list = routeros_interface_list.scarletwound-wan.name },
    { chain = "forward", action = "accept", in_interface = module.scarletwound-vlan2.vlan_interface, out_interface = routeros_interface_vlan.scarletwound-vlan3.name },
    { chain = "forward", action = "drop", disabled = true, comment = "drop forwarding that is not explicitly allowed" }
  ]
}

resource "routeros_ip_firewall_nat" "scarletwound-masquerade-list-vlan7" {
  provider = routeros.router-scarletwound

  action            = "masquerade"
  chain             = "srcnat"
  in_interface_list = routeros_interface_list.scarletwound-lan.name
  out_interface     = routeros_interface_vlan.scarletwound-vlan7.name
}
