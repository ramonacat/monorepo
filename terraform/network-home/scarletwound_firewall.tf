resource "routeros_ip_firewall_filter" "scarletwound-firewall-0" {
  provider = routeros.router-scarletwound

  chain            = "forward"
  action           = "fasttrack-connection"
  connection_state = "established,related"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-10" {
  provider = routeros.router-scarletwound

  chain            = "forward"
  action           = "accept"
  connection_state = "established,related,untracked"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-20" {
  provider = routeros.router-scarletwound

  chain            = "input"
  action           = "accept"
  connection_state = "established,related,untracked"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-30" {
  provider = routeros.router-scarletwound

  chain            = "input"
  action           = "drop"
  connection_state = "invalid"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-40" {
  provider = routeros.router-scarletwound

  chain    = "input"
  action   = "accept"
  protocol = "icmp"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-50" {
  provider = routeros.router-scarletwound

  chain       = "input"
  action      = "accept"
  dst_address = "127.0.0.1"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-60" {
  provider = routeros.router-scarletwound

  chain             = "input"
  action            = "drop"
  in_interface_list = "!${routeros_interface_list.scarletwound-lan.name}"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-70" {
  provider = routeros.router-scarletwound

  chain        = "forward"
  action       = "accept"
  ipsec_policy = "in,ipsec"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-80" {
  provider = routeros.router-scarletwound

  chain        = "forward"
  action       = "accept"
  ipsec_policy = "out,ipsec"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-90" {
  provider = routeros.router-scarletwound

  chain            = "forward"
  action           = "drop"
  connection_state = "invalid"
}

resource "routeros_ip_firewall_filter" "scarletwound-firewall-100" {
  provider = routeros.router-scarletwound

  chain                = "forward"
  action               = "drop"
  connection_nat_state = "!dstnat"
  connection_state     = "new"
  in_interface_list    = routeros_interface_list.scarletwound-wan.name
}

resource "routeros_ip_firewall_nat" "scarletwound-masquerade-list-vlan7" {
  provider          = routeros.router-scarletwound
  action            = "masquerade"
  chain             = "srcnat"
  in_interface_list = routeros_interface_list.scarletwound-lan.name
  out_interface     = routeros_interface_vlan.scarletwound-vlan7.name
}
