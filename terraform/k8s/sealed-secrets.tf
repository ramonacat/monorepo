resource "helm_release" "sealed-secrets" {
  name             = "sealed-secrets"
  chart            = "sealed-secrets"
  repository       = "https://bitnami.github.io/sealed-secrets"
  namespace        = "sealed-secrets"
  create_namespace = true
  version          = "2.19.1"

  values = [yamlencode({
    metrics = {
      prometheusRule = { enabled = true }
      serviceMonitor = { enabled = true }
      dashboards = {
        create    = var.create_grafana_dashboards
        labels    = { grafana_dashboard = "1" }
        namespace = "grafana"
      }
    }
  })]
}
