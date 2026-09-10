module "everbleed-firewall" {
  source = "../routeros-firewall"
  providers = {
    routeros = routeros.router-everbleed
  }
  rules_v4 = [
    { chain = "forward", action = "drop" },
    { chain = "input", action = "accept", protocol = "icmp" },
    { chain = "input", action = "accept", dst_address = "127.0.0.1", },
    { chain = "input", action = "accept", in_interface = routeros_interface_vlan.everbleed-vlan3.name, comment = "allow communication with other devices on the management vlan" },
    {
      chain        = "input",
      action       = "accept",
      dst_address  = local.everbleed_vlan3_ip,
      protocol     = "tcp",
      dst_port     = "80,443,8291,8729",
      in_interface = routeros_interface_vlan.everbleed-vlan2.name,
      comment      = "allow management access from workstations"
    },
    {
      chain        = "input",
      action       = "accept",
      protocol     = "tcp",
      dst_port     = "5678",
      in_interface = routeros_interface_vlan.everbleed-vlan2.name,
      comment      = "allow mikrotik's neighbour discovery from workstations"
    },
    { chain = "input", action = "drop" },
  ]

  rules_v6 = [
    {
      chain        = "input",
      action       = "accept",
      protocol     = "tcp",
      dst_port     = "80,443,8291,8729",
      in_interface = routeros_interface_vlan.everbleed-vlan2.name,
      comment      = "allow management access from workstations"
    },
    {
      chain        = "input",
      action       = "accept",
      protocol     = "tcp",
      dst_port     = "5678",
      in_interface = routeros_interface_vlan.everbleed-vlan2.name,
      comment      = "allow mikrotik's neighbour discovery from workstations"
    },
    { chain = "input", action = "accept", protocol = "icmpv6" },
    { chain = "input", action = "drop" },
    { chain = "forward", action = "drop" },
  ]
}
