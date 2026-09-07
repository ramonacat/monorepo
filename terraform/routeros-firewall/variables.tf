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
