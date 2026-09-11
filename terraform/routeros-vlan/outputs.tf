output "vlan_interface" {
  value = routeros_interface_vlan.main.name
}

output "vlan_id" {
  value = var.vlan_id
}

output "cidr" {
  value = var.cidr
}
