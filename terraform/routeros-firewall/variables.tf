variable "rules_v4" {
  type = list(object({
    action               = string
    chain                = string
    comment              = optional(string)
    connection_nat_state = optional(string)
    connection_state     = optional(string)
    disabled             = optional(bool, false)
    dst_address          = optional(string)
    dst_port             = optional(string)
    in_interface         = optional(string)
    in_interface_list    = optional(string, "all")
    out_interface        = optional(string)
    out_interface_list   = optional(string)
    protocol             = optional(string)
    src_address          = optional(string, "0.0.0.0/0")
    src_port             = optional(string)
    packet_mark          = optional(string)
  }))
}

variable "rules_v6" {
  type = list(object({
    action             = string
    chain              = string
    comment            = optional(string)
    connection_state   = optional(string)
    disabled           = optional(bool, false)
    dst_address        = optional(string)
    dst_port           = optional(string)
    in_interface       = optional(string)
    in_interface_list  = optional(string, "all")
    out_interface      = optional(string)
    out_interface_list = optional(string)
    protocol           = optional(string)
    src_address        = optional(string, "::/0")
    src_port           = optional(string)
    packet_mark        = optional(string)
  }))
}
