terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.65.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.29.2"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = ">= 0.12.1"
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

  name               = each.value
  placement_group_id = hcloud_placement_group.nodes.id
  ssh_keys           = var.ssh_keys
  dns_zone_name      = var.dns_zone_name
  tailscale_tags     = var.control_plane_nodes[each.value].tailscale_tags
  firewall_ids       = var.firewall_ids
  server_type        = "cx33"
  before_node_update = { command = "kubectl", arguments = ["drain", "--delete-emptydir-data", "--ignore-daemonsets", each.value] }
  after_node_update  = { command = "kubectl", arguments = ["uncordon", each.value] }
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
  version          = "1.98.4"

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

resource "helm_release" "prometheus" {
  name             = "prometheus"
  chart            = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  namespace        = "prometheus"
  create_namespace = true
  version          = "29.12.0"

  values = [yamlencode({
    server = {
      persistentVolume = {
        size = "1Gi"
      }
      replicaCount = 2
      statefulSet = {
        enabled = true
      }
    }
    alertmanager = {
      replicaCount = 2
      service = {
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9093"
        }
      }
      persistence = {
        size = "128Mi"
      }
    }
  })]
}

resource "helm_release" "kured" {
  name             = "kured"
  chart            = "kured"
  repository       = "https://kubereboot.github.io/charts"
  namespace        = "kured"
  create_namespace = true
  version          = "6.0.0"

  set = [
    {
      name  = "configuration.rebootCommand",
      value = "/run/current-system/sw/bin/systemctl reboot",
    }
  ]
}

resource "hcloud_server_network" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  server_id = module.k8s--control-plane-nodes[each.value].server_id
  subnet_id = var.subnet_id
  ip        = var.control_plane_nodes[each.value].private_ipv4
}

