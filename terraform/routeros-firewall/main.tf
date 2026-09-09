terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

locals {
  rule-map = { for idx, rule in var.rules : format("%03d", idx) => rule }
}

resource "routeros_ip_firewall_filter" "rules" {
  action               = each.value.action
  chain                = each.value.chain
  comment              = each.value.comment
  connection_nat_state = each.value.connection_nat_state
  connection_state     = each.value.connection_state
  disabled             = each.value.disabled
  dst_address          = each.value.dst_address
  dst_port             = each.value.dst_port
  for_each             = local.rule-map
  in_interface         = each.value.in_interface
  in_interface_list    = each.value.in_interface_list
  out_interface        = each.value.out_interface
  protocol             = each.value.protocol
  src_address          = each.value.src_address
}

resource "routeros_move_items" "firewall-filter" {
  resource_path = "/ip/firewall/filter"
  sequence      = [for i, _ in local.rule-map : routeros_ip_firewall_filter.rules[i].id]
  depends_on    = [routeros_ip_firewall_filter.rules]
}
