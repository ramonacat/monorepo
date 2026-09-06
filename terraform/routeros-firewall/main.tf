terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

variable "rules" {
  type = list(object({
    chain                = string
    action               = string
    connection_state     = optional(string)
    connection_nat_state = optional(string)
    out_interface        = optional(string)
    in_interface_list    = optional(string, "all")
    out_interface_list   = optional(string)
    src_address          = optional(string, "0.0.0.0/0")
    dst_address          = optional(string)
    src_port             = optional(string)
    dst_port             = optional(string)
    protocol             = optional(string)
    comment              = optional(string)
    disabled             = optional(bool, false)
  }))
}
locals {
  rule-map = { for idx, rule in var.rules : format("%03d", idx) => rule }
}

resource "routeros_ip_firewall_filter" "rules" {
  for_each             = local.rule-map
  chain                = each.value.chain
  action               = each.value.action
  comment              = each.value.comment
  disabled             = each.value.disabled
  connection_state     = each.value.connection_state
  connection_nat_state = each.value.connection_nat_state
  in_interface_list    = each.value.in_interface_list
  src_address          = each.value.src_address
  dst_address          = each.value.dst_address
  dst_port             = each.value.dst_port
  protocol             = each.value.protocol
  out_interface        = each.value.out_interface
}

resource "routeros_move_items" "firewall-filter" {
  resource_path = "/ip/firewall/filter"
  sequence      = [for i, _ in local.rule-map : routeros_ip_firewall_filter.rules[i].id]
  depends_on    = [routeros_ip_firewall_filter.rules]
}
