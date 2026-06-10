module "k8s--darkmore" {
  source = "./k8s"

  dns_zone_name = dnsimple_zone.ramona-fun.name
  ssh_keys      = [hcloud_ssh_key.ramona.id]
  control_plane_nodes = {
    "darkmore-control-plane-0" = { tailscale_tags = split(" ", data.external.tailscale_tags.result["darkmore-control-plane-0"]) },
    "darkmore-control-plane-1" = { tailscale_tags = split(" ", data.external.tailscale_tags.result["darkmore-control-plane-1"]) },
    "darkmore-control-plane-2" = { tailscale_tags = split(" ", data.external.tailscale_tags.result["darkmore-control-plane-2"]) },
  }
}
