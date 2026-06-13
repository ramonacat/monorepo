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
  control_plane_nodes = { for node in jsondecode(file("./k8s-nodes.json"))["darkmore"] : node.hostname => {
    tailscale_tags = split(" ", data.external.tailscale_tags.result[node.hostname]), private_ipv4 : node.ip
  } }
}

resource "tailscale_oauth_client" "kubernetes" {
  scopes = ["services", "devices:core", "auth_keys"]
  tags   = ["tag:k8s-operator"]
}

resource "kubernetes_namespace_v1" "kube-flannel" {
  metadata {
    name = "kube-flannel"

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "flannel" {
  name       = "flannel"
  chart      = "flannel"
  repository = "https://flannel-io.github.io/flannel/"
  version    = "v0.28.5"
  namespace  = kubernetes_namespace_v1.kube-flannel.metadata[0].name

  set = [{
    name  = "podCidr",
    value = "10.72.0.0/16"
  }]
}

resource "helm_release" "tailscale" {
  name             = "tailscale"
  chart            = "tailscale-operator"
  repository       = "https://pkgs.tailscale.com/helmcharts"
  namespace        = "tailscale"
  create_namespace = true

  lifecycle {
    ignore_changes = [create_namespace]
  }

  set_sensitive = [
    {
      name  = "oauth.clientId"
      value = tailscale_oauth_client.kubernetes.id
    },
    {
      name  = "oauth.clientSecret"
      value = tailscale_oauth_client.kubernetes.key
    }
  ]
}

resource "helm_release" "kured" {
  name             = "kured"
  chart            = "kured"
  repository       = "https://kubereboot.github.io/charts"
  namespace        = "kured"
  create_namespace = true

  set = [
    {
      name  = "configuration.rebootCommand",
      value = "/run/current-system/sw/bin/systemctl reboot",
    }
  ]
}
