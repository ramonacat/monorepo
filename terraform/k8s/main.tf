terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.65.0"
    }
  }
}

resource "hcloud_placement_group" "nodes" {
  name = "${var.name}-nodes"
  type = "spread"
}

module "k8s--control-plane-nodes" {
  source   = "../node"
  for_each = toset(keys(var.control_plane_nodes))

  name                = each.value
  placement_group_id  = hcloud_placement_group.nodes.id
  ssh_keys            = var.ssh_keys
  dns_zone_name       = var.dns_zone_name
  tailscale_tags      = var.control_plane_nodes[each.value].tailscale_tags
  install_private_key = var.install_private_key
}

resource "hcloud_server_network" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  server_id = module.k8s--control-plane-nodes[each.value].server_id
  subnet_id = var.subnet_id
  ip        = var.control_plane_nodes[each.value].private_ipv4
}
