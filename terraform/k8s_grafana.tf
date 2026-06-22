resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "grafana"
  repository       = "https://grafana-community.github.io/helm-charts"
  namespace        = "grafana"
  create_namespace = true
  version          = "12.4.8"

  values = [yamlencode({
    replicas = 2
    route = {
      main = {
        enabled    = true
        hostnames  = ["grafana.infrastructure.ramona.fun"]
        parentRefs = [{ name = "gateway-tailscale", namespace = "kgateway-system" }]
      }
    }
    serviceMonitor = { enabled = true }
    persistence = {
      enabled          = true
      storageClassName = "longhorn"
      size             = "192Mi"
      accessModes      = ["ReadWriteMany"]
    }
    sidecar = {
      alerts      = { enabled = true, searchNamespace = "ALL" }
      dashboards  = { enabled = true, searchNamespace = "ALL" }
      datasources = { enabled = true, searchNamespace = "ALL" }
      plugins     = { enabled = true, searchNamespace = "ALL" }
      notifiers   = { enabled = true, searchNamespace = "ALL" }
    }
    datasources = {
      "datasources.yaml" = {
        apiVersion        = 1
        deleteDatasources = [{ name = "prometheus" }]
      }
    }
  })]
}

