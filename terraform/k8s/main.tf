module "k8s--control-plane-nodes" {
  source   = "../node"
  for_each = toset(keys(var.control_plane_nodes))

  ssh_keys       = var.ssh_keys
  name           = each.value
  dns_zone_name  = var.dns_zone_name
  tailscale_tags = var.control_plane_nodes[each.value].tailscale_tags
}
