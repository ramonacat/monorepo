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

  values = [yamlencode({
  })]

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
  version          = "6.0.0"

  values = [yamlencode({
    configuration = {
      rebootCommand = "/run/current-system/sw/bin/systemctl reboot"
      period        = "1m0s"
    }
  })]
}

resource "helm_release" "kube-prometheus-stack" {
  name             = "kube-prometheus-stack"
  chart            = "oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack"
  namespace        = "kube-prometheus-stack"
  create_namespace = true
  version          = "86.3.2"

  values = [yamlencode({
    alertmanager = {
      alertmanagerSpec = {
        replicas = 2
      }
    }
    grafana = {
      enabled = false

      // TODO these should come from variables, as grafana isn't an inherent dependency of the cluster
      namespaceOverride      = "grafana"
      forceDeployDatasources = true
      forceDeployDashboards  = true

      admin = {
        existingSecret = "grafana"
      }
    }
    prometheus = {
      prometheusSpec = {
        replicas      = 2
        retentionSize = "4900MiB"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "ceph-block"
              accessModes      = ["ReadWriteOnce"]
              resources        = { requests = { storage = "5Gi" } }
            }
          }
        }
      }
    }
  })]
}

resource "hcloud_server_network" "node" {
  for_each = toset(keys(var.control_plane_nodes))

  server_id = module.k8s--control-plane-nodes[each.value].server_id
  subnet_id = var.subnet_id
  ip        = var.control_plane_nodes[each.value].private_ipv4
}

