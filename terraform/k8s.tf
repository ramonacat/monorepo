moved {
  from = tailscale_oauth_client.kubernetes
  to   = module.k8s--darkmore.tailscale_oauth_client.kubernetes
}

moved {
  from = kubernetes_namespace_v1.kube-flannel
  to   = module.k8s--darkmore.kubernetes_namespace_v1.kube-flannel
}

moved {
  from = helm_release.tailscale
  to   = module.k8s--darkmore.helm_release.tailscale
}

moved {
  from = helm_release.rook-ceph
  to   = module.k8s--darkmore.helm_release.rook-ceph
}

moved {
  from = helm_release.kured
  to   = module.k8s--darkmore.helm_release.kured
}

moved {
  from = helm_release.flannel
  to   = module.k8s--darkmore.helm_release.flannel
}

moved {
  from = helm_release.ceph-csi-drivers
  to   = module.k8s--darkmore.helm_release.ceph-csi-drivers
}

moved {
  from = module.k8s--darkmore.helm_release.grafana
  to   = helm_release.grafana
}

resource "hcloud_network_subnet" "k8s" {
  network_id   = hcloud_network.net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_network_subnet" "k8s-lb" {
  network_id   = hcloud_network.net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.1.0.0/24"
}

module "k8s--darkmore" {
  source = "./k8s"

  name          = "darkmore"
  network_id    = hcloud_network.net.id
  subnet_id     = hcloud_network_subnet.k8s.id
  dns_zone_name = dnsimple_zone.ramona-fun.name
  ssh_keys      = [hcloud_ssh_key.ramona.id, hcloud_ssh_key.ci.id]
  firewall_ids  = [hcloud_firewall.fw.id]
  nodes = {
    for node in jsondecode(file("./k8s-nodes.json"))["darkmore"]["nodes"] : node.hostname =>
    {
      tailscale_tags   = split(" ", data.external.tailscale_tags.result[node.hostname]),
      private_ipv4     = node.ip,
      is_control_plane = node.isControlPlane
    }
  }
  hcloud_token    = var.kubernetes_darkmore_hcloud_token
  dnsimple_token  = var.kubernetes_darkmore_dnsimple_token
  discord_webhook = var.kubernetes_darkmore_discord_webhook
  vault_pki       = vault_mount.pki-hosts.path
  vault_role      = vault_pki_secret_backend_role.hosts.name
}

