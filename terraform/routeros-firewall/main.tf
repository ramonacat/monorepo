terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

locals {
  rule-map-v4 = { for idx, rule in var.rules_v4 : format("%03d", idx) => rule }
  rule-map-v6 = { for idx, rule in var.rules_v6 : format("%03d", idx) => rule }
}

resource "routeros_ip_firewall_filter" "rules" {
  for_each = local.rule-map-v4

  action               = each.value.action
  chain                = each.value.chain
  comment              = each.value.comment
  connection_nat_state = each.value.connection_nat_state
  connection_state     = each.value.connection_state
  disabled             = each.value.disabled
  dst_address          = each.value.dst_address
  dst_port             = each.value.dst_port
  in_interface         = each.value.in_interface
  in_interface_list    = each.value.in_interface_list
  out_interface        = each.value.out_interface
  protocol             = each.value.protocol
  src_address          = each.value.src_address
  packet_mark          = each.value.packet_mark
}

resource "routeros_move_items" "firewall-filter" {
  resource_path = "/ip/firewall/filter"
  sequence      = [for i, _ in local.rule-map-v4 : routeros_ip_firewall_filter.rules[i].id]
  depends_on    = [routeros_ip_firewall_filter.rules]
}

resource "routeros_ipv6_firewall_filter" "rules" {
  for_each = local.rule-map-v6

  action            = each.value.action
  chain             = each.value.chain
  comment           = each.value.comment
  connection_state  = each.value.connection_state
  disabled          = each.value.disabled
  dst_address       = each.value.dst_address
  dst_port          = each.value.dst_port
  in_interface      = each.value.in_interface
  in_interface_list = each.value.in_interface_list
  out_interface     = each.value.out_interface
  protocol          = each.value.protocol
  src_address       = each.value.src_address
  packet_mark       = each.value.packet_mark
}

resource "routeros_move_items" "firewall-filter-v6" {
  resource_path = "/ipv6/firewall/filter"
  sequence      = [for i, _ in local.rule-map-v6 : routeros_ipv6_firewall_filter.rules[i].id]
  depends_on    = [routeros_ipv6_firewall_filter.rules]
}
