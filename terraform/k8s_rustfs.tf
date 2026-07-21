resource "helm_release" "rustfs" {
  name             = "rustfs"
  chart            = "rustfs"
  repository       = "https://charts.rustfs.com"
  namespace        = "rustfs"
  create_namespace = true
  version          = "0.10.0"

  values = [yamlencode({
    replicaCount  = 3
    drivesPerNode = 1
    secret = {
      existingSecret = "rustfs-root-key"
    }
    config = {
      rustfs = {
        domains = "rustfs.internal.ramona.fun"
        metrics = { enabled = true }
      }
    }
    gatewayApi = {
      enabled         = true
      gatewayClass    = "kgateway"
      listeners       = [{ https = { name = "web", port = 443 } }]
      hostname        = "rustfs.internal.ramona.fun"
      existingGateway = { name = "gateway-tailscale-internal", namespace = "kgateway-system" }
    }
    storageclass = {
      name            = "longhorn"
      dataStorageSize = "1Gi"
    }
  })]
}

