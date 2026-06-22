resource "helm_release" "opensearch-cluster" {
  name             = "opensearch-cluster"
  chart            = "opensearch"
  repository       = "https://opensearch-project.github.io/helm-charts/"
  namespace        = "opensearch-cluster"
  create_namespace = true
  version          = "3.7.0"

  values = [yamlencode({
    envFrom        = [{ secretRef = { name = "initial-admin" } }]
    serviceMonitor = { enabled = true }
  })]
}

resource "helm_release" "opensearch-dashboards" {
  name             = "opensearch-dashboards"
  chart            = "opensearch-dashboards"
  repository       = "https://opensearch-project.github.io/helm-charts/"
  namespace        = "opensearch-dashboards"
  create_namespace = true
  version          = "3.7.0"

  values = [yamlencode({
    replicaCount   = 2
    serviceMonitor = { enabled = true }
  })]
}
