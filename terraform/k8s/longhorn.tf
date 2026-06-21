resource "helm_release" "longhorn" {
  name             = "longhorn"
  chart            = "longhorn"
  repository       = "https://charts.longhorn.io"
  namespace        = "longhorn-system"
  create_namespace = true
  version          = "1.12.0"

  values = [yamlencode({
    httproute = {
      enabled    = true
      hostnames  = ["longhorn.infrastructure.ramona.fun"]
      parentRefs = [{ name = "gateway-tailscale", namespace = "kgateway-system" }]
      metrics = {
        serviceMonitor = { enabled = true }
      }
    }
  })]
}

/*
resource "hcloud_volume" "longhorn" {
  for_each = toset(keys(var.control_plane_nodes))

  name      = each.value
  size      = 10
  server_id = module.k8s--control-plane-nodes[each.key].server_id
}

resource "kubernetes_annotations" "longhorn" {
  for_each = toset(keys(var.control_plane_nodes))

  kind        = "Node"
  metadata {
    name = each.key
  }

  annotations = {
    "node.longhorn.io/default-disks-config" = jsonencode([

    ])
  }
}*/
