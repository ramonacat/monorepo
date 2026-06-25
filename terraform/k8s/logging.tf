resource "helm_release" "fluent-operator" {
  name             = "fluent-operator"
  chart            = "oci://ghcr.io/fluent/helm-charts/fluent-operator"
  namespace        = "fluent-operator"
  create_namespace = true
  version          = "4.2.0"

  values = [yamlencode({
    operator = {
      resources = {
        limits = {
          memory = "512Mi"
        }
        requests = {
          memory = "128Mi"
        }
      }
    }
    fluentbit = {
      ports = [6514]
      envVars = [
        {
          name = "POSTGRES_USERNAME"
          valueFrom = {
            secretKeyRef = { key = "POSTGRES_USERNAME", name = "fluentbit" }
          }
        },
        {
          name = "POSTGRES_PASSWORD"
          valueFrom = {
            secretKeyRef = { key = "POSTGRES_PASSWORD", name = "fluentbit" }
          }
        },
      ]
      serviceMonitor = { enable = true }
      // the output is defined in a customization because chart does no support customPlugin
    }
  })]
}
