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
    }
    metrics = {
      serviceMonitor = { enabled = true }
    }
    longhornManager = { log = { format = "json" } }
    longhornDriver  = { log = { format = "json" } }
  })]
}
