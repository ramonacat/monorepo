variable "vlan_id" {
  type = number
}

variable "interface" {
  type = string
}

variable "bridge" {
  type    = string
  default = vars.interface
}

variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "tagged_ports" {
  type = list(string)
}

variable "untagged_ports" {
  type = list(string)
}
