resource "helm_release" "crowdsec" {
  name             = "crowdsec"
  chart            = "crowdsec"
  repository       = "https://crowdsecurity.github.io/helm-charts"
  namespace        = "crowdsec"
  create_namespace = true
  version          = "0.24.0"

  values = [yamlencode({
    container_runtime = "containerd"
    config = {
      "config.yaml.local" = yamlencode({
        api = {
          server = {
            auto_registration = {
              enabled = true
              token   = "$${REGISTRATION_TOKEN}"
              allowed_ranges = [
                "127.0.0.1/8",
                "10.0.0.0/8"
              ]
            }
          }
        }
        db_config = {
          type     = "postgresql"
          user     = "$${DB_USERNAME}"
          password = "$${DB_PASSWORD}"
          port     = 5432
          db_name  = "crowdsec"
          host     = "cloudnative-pg-database-cluster-pooler-rw.cloudnative-pg-database"
        }
        prometheus = {
          enabled = true
          level   = "aggregated"
        }
      })
    }
    lapi = {
      replicas = 2
      metrics  = { serviceMonitor = { enabled = true }, podMonitor = { enabled = true } }
      envFrom = [
        { secretRef = { name = "crowdsec" } },
        { secretRef = { name = "crowdsec-api-key" } },
      ]
      persistentVolume = {
        data   = { size = "128Mi", accessModes = ["ReadWriteMany"], storageClassName = "longhorn" }
        config = { enabled = false }
      }
      storeCAPICredentialsInSecret      = true
      storeLAPICscliCredentialsInSecret = true
    }
    agent = {
      metrics = { serviceMonitor = { enabled = true }, podMonitor = { enabled = true } }
      acquisition = [
        { namespace = "kgateway-system", podName = "gateway-*", program = "envoy" }
      ]
      envFrom = [
        { secretRef = { name = "crowdsec-api-key" } },
      ]
    }
  })]
}
