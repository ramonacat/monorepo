resource "hcloud_network_subnet" "k8s" {
  network_id   = hcloud_network.net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.70.0.0/24"
}

module "k8s--darkmore" {
  source = "./k8s"

  name          = "darkmore"
  subnet_id     = hcloud_network_subnet.k8s.id
  dns_zone_name = dnsimple_zone.ramona-fun.name
  ssh_keys      = [hcloud_ssh_key.ramona.id, hcloud_ssh_key.ci.id]
  firewall_ids  = [hcloud_firewall.fw.id]

  control_plane_nodes = {
    "darkmore-control-plane-0" = { tailscale_tags = split(" ", data.external.tailscale_tags.result["darkmore-control-plane-0"]), private_ipv4 : "10.70.0.10" },
    "darkmore-control-plane-1" = { tailscale_tags = split(" ", data.external.tailscale_tags.result["darkmore-control-plane-1"]), private_ipv4 : "10.70.0.11" },
    "darkmore-control-plane-2" = { tailscale_tags = split(" ", data.external.tailscale_tags.result["darkmore-control-plane-2"]), private_ipv4 : "10.70.0.12" },
  }
}
