module "scarletwound-firewall" {
  source = "../routeros-firewall"
  providers = {
    routeros = routeros.router-scarletwound
  }
  rules_v4 = [
    { chain = "forward", action = "accept", connection_state = "established,related", packet_mark = "internet" },
    { chain = "forward", action = "accept", connection_state = "established,related", packet_mark = "high-priority" },
    { chain = "forward", action = "fasttrack-connection", connection_state = "established,related", in_interface_list = routeros_interface_list.scarletwound-lan.name, out_interface_list = routeros_interface_list.scarletwound-lan.name },
    { chain = "forward", action = "accept", connection_state = "established,related,untracked" },
    { chain = "input", action = "accept", connection_state = "established,related,untracked" },
    { chain = "input", action = "drop", connection_state = "invalid", },
    { chain = "input", action = "accept", protocol = "icmp" },
    { chain = "input", action = "accept", dst_address = "127.0.0.1", },
    { chain = "input", action = "accept", in_interface = routeros_interface_vlan.scarletwound-vlan3.name, comment = "allow communication with other devices on the management vlan" },
    {
      chain        = "input",
      action       = "accept",
      dst_address  = local.scarletwound_vlan3_ip,
      protocol     = "tcp",
      dst_port     = "80,443,8291,8729",
      in_interface = module.scarletwound-vlan2.vlan_interface,
      comment      = "allow management access from workstations"
    },
    {
      chain        = "input",
      action       = "accept",
      protocol     = "tcp",
      dst_port     = "5678",
      in_interface = module.scarletwound-vlan2.vlan_interface,
      comment      = "allow mikrotik's neighbour discovery from workstations"
    },
    {
      chain       = "input",
      action      = "accept",
      dst_address = local.scarletwound_vlan3_ip,
      protocol    = "tcp",
      dst_port    = "8729",
      src_address = routeros_ip_dhcp_server_lease.scarletwound-vlan6-homeassistant.address,
      comment     = "allow homeassistant api access"
    },
    {
      chain    = "input",
      action   = "accept",
      protocol = "tcp",
      dst_port = "53",
      comment  = "dns/tcp"
    },
    {
      chain    = "input",
      action   = "accept",
      protocol = "udp",
      dst_port = "53,5353",
      comment  = "dns/udp"
    },
    {
      chain    = "input",
      action   = "accept",
      protocol = "udp",
      dst_port = "5351",
      comment  = "NAT PMP"
    },
    { chain = "input", action = "drop" },
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
      chain       = "forward",
      action      = "accept",
      src_address = routeros_ip_dhcp_server_lease.scarletwound-tv.address,
      dst_address = routeros_ip_dhcp_server_lease.scarletwound-hallewell.address,
      dst_port    = "8096"
      protocol    = "tcp"
      comment     = "tv -> hallewell (jellyfin)"
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

  rules_v6 = [
    {
      chain        = "input",
      action       = "accept",
      protocol     = "tcp",
      dst_port     = "80,443,8291,8729",
      in_interface = module.scarletwound-vlan2.vlan_interface,
      comment      = "allow management access from workstations"
    },
    {
      chain        = "input",
      action       = "accept",
      protocol     = "tcp",
      dst_port     = "5678",
      in_interface = module.scarletwound-vlan2.vlan_interface,
      comment      = "allow mikrotik's neighbour discovery from workstations"
    },
    { chain = "input", action = "accept", protocol = "icmpv6" },
    { chain = "input", action = "drop" },
    { chain = "forward", action = "drop" },
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

resource "routeros_ip_firewall_mangle" "scarletwound-mark-from-internet-prerouting" {
  provider = routeros.router-scarletwound

  chain            = "prerouting"
  action           = "mark-packet"
  dst_address_list = "!${routeros_firewall_addr_list.scarletwound-lan-private1.list}"
  new_packet_mark  = "internet"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-to-internet-prerouting" {
  provider = routeros.router-scarletwound

  chain            = "prerouting"
  action           = "mark-packet"
  src_address_list = "!${routeros_firewall_addr_list.scarletwound-lan-private1.list}"
  new_packet_mark  = "internet"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-from-internet-forward" {
  provider = routeros.router-scarletwound

  chain            = "forward"
  action           = "mark-packet"
  dst_address_list = "!${routeros_firewall_addr_list.scarletwound-lan-private1.list}"
  new_packet_mark  = "internet"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-to-internet-forward" {
  provider = routeros.router-scarletwound

  chain            = "forward"
  action           = "mark-packet"
  src_address_list = "!${routeros_firewall_addr_list.scarletwound-lan-private1.list}"
  new_packet_mark  = "internet"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-from-internet-forward-byvlan" {
  provider = routeros.router-scarletwound

  chain           = "prerouting"
  action          = "mark-packet"
  in_interface    = routeros_interface_vlan.scarletwound-vlan7.name
  new_packet_mark = "internet"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-to-internet-forward-byvlan" {
  provider = routeros.router-scarletwound

  chain           = "forward"
  action          = "mark-packet"
  out_interface   = routeros_interface_vlan.scarletwound-vlan7.name
  new_packet_mark = "internet"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-dns-udp-prerouting" {
  provider = routeros.router-scarletwound

  chain           = "prerouting"
  action          = "mark-packet"
  protocol        = "udp"
  port            = "53,5353"
  new_packet_mark = "high-priority"
}

resource "routeros_ip_firewall_mangle" "scarletwound-mark-dns-udp-forward" {
  provider = routeros.router-scarletwound

  chain           = "forward"
  action          = "mark-packet"
  protocol        = "udp"
  port            = "53,5353"
  new_packet_mark = "high-priority"
}

resource "routeros_move_items" "scarletwound-firewall-mangle" {
  provider      = routeros.router-scarletwound
  resource_path = "/ip/firewall/mangle"

  sequence = [
    routeros_ip_firewall_mangle.scarletwound-mark-dns-udp-prerouting.id,
    routeros_ip_firewall_mangle.scarletwound-mark-dns-udp-forward.id,
    routeros_ip_firewall_mangle.scarletwound-mark-from-internet-prerouting.id,
    routeros_ip_firewall_mangle.scarletwound-mark-to-internet-prerouting.id,
    routeros_ip_firewall_mangle.scarletwound-mark-from-internet-forward.id,
    routeros_ip_firewall_mangle.scarletwound-mark-to-internet-forward.id,
  ]
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

