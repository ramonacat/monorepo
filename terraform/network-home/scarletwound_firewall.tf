module "scarletwound-firewall" {
  source = "../routeros-firewall"
  providers = {
    routeros = routeros.router-scarletwound
  }
  rules = [
    { chain = "forward", action = "fasttrack-connection", connection_state = "established,related", packet_mark = "!dampen" },
    { chain = "forward", action = "accept", connection_state = "established,related,untracked" },
    { chain = "input", action = "accept", connection_state = "established,related,untracked" },
    { chain = "input", action = "drop", connection_state = "invalid", },
    { chain = "input", action = "accept", protocol = "icmp" },
    { chain = "input", action = "accept", dst_address = "127.0.0.1", },
    { chain = "input", action = "drop", in_interface_list = "!${routeros_interface_list.scarletwound-lan.name}" },
    { chain = "forward", action = "drop", connection_state = "invalid" },
    { chain = "forward", action = "drop", connection_nat_state = "!dstnat", connection_state = "new", in_interface_list = routeros_interface_list.scarletwound-wan.name },
    { chain = "forward", action = "accept", in_interface = module.scarletwound-vlan2.vlan_interface, out_interface = routeros_interface_vlan.scarletwound-vlan3.name },
    {
      chain             = "forward",
      action            = "accept",
      in_interface_list = routeros_interface_list.scarletwound-all-clients.name,
      dst_address       = routeros_ip_dhcp_server_lease.scarletwound-printer.address,
      dst_port          = "80,443,631,54921",
      protocol          = "tcp",
      comment           = "printer access"
    },
    {
      chain             = "forward",
      action            = "accept",
      in_interface_list = routeros_interface_list.scarletwound-lan.name,
      dst_address       = routeros_ip_dhcp_server_lease.scarletwound-hallewell.address,
      dst_port          = "80,443",
      protocol          = "tcp",
      comment           = "front proxy for home services access for allowed vlans"
    },
    {
      chain             = "forward",
      action            = "accept",
      in_interface_list = "${routeros_interface_list.scarletwound-internet-access.name}",
      out_interface     = routeros_interface_vlan.scarletwound-vlan7.name,
      comment           = "internet access"
    },
    {
      chain       = "forward",
      action      = "accept",
      src_address = routeros_ip_dhcp_server_lease.scarletwound-vlan6-homeassistant.address,
      dst_address = routeros_ip_dhcp_server_lease.scarletwound-tv.address,
      comment     = "homeassistant -> tv"
    },
    {
      chain       = "forward",
      action      = "accept",
      src_address = routeros_ip_dhcp_server_lease.scarletwound-vlan6-homeassistant.address,
      dst_address = routeros_ip_dhcp_server_lease.scarletwound-printer.address,
      comment     = "homeassistant -> printer"
    },
    {
      chain       = "forward",
      action      = "accept",
      src_address = routeros_ip_dhcp_server_lease.scarletwound-vlan6-homeassistant.address,
      dst_address = routeros_ip_dhcp_server_lease.scarletwound-hallewell.address,
      dst_port    = "111,2049"
      protocol    = "udp"
      comment     = "homeassistant -> hallewell (nfs/udp)"
    },
    {
      chain       = "forward",
      action      = "accept",
      src_address = routeros_ip_dhcp_server_lease.scarletwound-vlan6-homeassistant.address,
      dst_address = routeros_ip_dhcp_server_lease.scarletwound-hallewell.address,
      dst_port    = "111,2049"
      protocol    = "tcp"
      comment     = "homeassistant -> hallewell (nfs/tcp)"
    },
    {
      chain         = "forward",
      action        = "accept",
      src_address   = routeros_ip_dhcp_server_lease.scarletwound-vlan6-homeassistant.address,
      out_interface = routeros_interface_vlan.scarletwound-vlan7.name,
      comment       = "internet access for homeassistant"
    },
    {
      chain    = "forward",
      action   = "accept",
      protocol = "udp",
      dst_port = 41641,
      comment  = "tailscale"
    },
    {
      chain    = "forward",
      action   = "drop",
      disabled = false,
      comment  = "drop forwarding that is not explicitly allowed"
    }
  ]
}

resource "routeros_interface_list" "scarletwound-all-clients" {
  provider = routeros.router-scarletwound

  name = "all-clients"
}

resource "routeros_ip_firewall_nat" "scarletwound-masquerade-list-vlan7" {
  provider = routeros.router-scarletwound

  action            = "masquerade"
  chain             = "srcnat"
  in_interface_list = routeros_interface_list.scarletwound-lan.name
  out_interface     = routeros_interface_vlan.scarletwound-vlan7.name
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-from-servers" {
  provider = routeros.router-scarletwound

  chain            = "forward"
  action           = "mark-packet"
  in_interface     = module.scarletwound-vlan4.vlan_interface
  dst_address_list = "!${routeros_firewall_addr_list.scarletwound-lan-private1.list}"
  new_packet_mark  = "dampen"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-to-servers" {
  provider = routeros.router-scarletwound

  chain            = "forward"
  action           = "mark-packet"
  out_interface    = module.scarletwound-vlan4.vlan_interface
  src_address_list = "!${routeros_firewall_addr_list.scarletwound-lan-private1.list}"
  new_packet_mark  = "dampen"
}

resource "routeros_firewall_addr_list" "scarletwound-lan-private1" {
  provider = routeros.router-scarletwound

  list    = "lan"
  address = "10.0.0.0/8"
}

resource "routeros_firewall_addr_list" "scarletwound-lan-cgnat" {
  provider = routeros.router-scarletwound

  list    = "lan"
  address = "100.64.0.0/10"
}

resource "routeros_firewall_addr_list" "scarletwound-lan-link-local" {
  provider = routeros.router-scarletwound

  list    = "lan"
  address = "169.254.0.0/16"
}

resource "routeros_firewall_addr_list" "scarletwound-lan-private2" {
  provider = routeros.router-scarletwound

  list    = "lan"
  address = "172.16.0.0/12"
}

resource "routeros_firewall_addr_list" "scarletwound-lan-private3" {
  provider = routeros.router-scarletwound

  list    = "lan"
  address = "192.168.0.0/16"
}

