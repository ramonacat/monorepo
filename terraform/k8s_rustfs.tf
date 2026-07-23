resource "helm_release" "rustfs" {
  name             = "rustfs"
  chart            = "rustfs"
  repository       = "https://charts.rustfs.com"
  namespace        = "rustfs"
  create_namespace = true
  version          = "0.11.0"

  values = [yamlencode({
    replicaCount  = 3
    drivesPerNode = 1
    secret = {
      existingSecret = "rustfs-root-key"
    }
    config = {
      rustfs = {
        domains   = "rustfs.infrastructure.ramona.fun"
        metrics   = { enabled = true }
        log_level = "WARN"
      }
    }
    gatewayApi = {
      enabled         = true
      gatewayClass    = "kgateway"
      listeners       = { https = { name = "https", port = 443 } }
      hostname        = "rustfs.infrastructure.ramona.fun"
      existingGateway = { name = "gateway-tailscale", namespace = "kgateway-system" }
    }
    storageclass = {
      name            = "longhorn"
      dataStorageSize = "5Gi"
      logStorageSize  = "3Gi"
    }
  })]
}

