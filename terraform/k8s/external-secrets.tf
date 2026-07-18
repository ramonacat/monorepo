resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  chart            = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "2.8.0"

  values = [yamlencode({
    replicaCount        = 2
    leaderElect         = true
    openshiftFinalizers = false
    serviceMonitor      = { enabled = true }
    grafanaDashboard    = { enabled = true }
    podDisruptionBudget = { enabled = true }
  })]
}
