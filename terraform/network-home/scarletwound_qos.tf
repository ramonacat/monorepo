resource "routeros_queue_simple" "scarletwound-vlan4" {
  provider = routeros.router-scarletwound

  name      = "vlan4"
  target    = [module.scarletwound-vlan4.vlan_interface]
  limit_at  = "4M/40M"
  max_limit = "6M/50M"
}
