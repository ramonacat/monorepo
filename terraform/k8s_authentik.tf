resource "helm_release" "authentik" {
  name             = "authentik"
  chart            = "authentik"
  repository       = "https://charts.goauthentik.io"
  namespace        = "authentik"
  create_namespace = true
  version          = "2026.5.3"

  values = [yamlencode({
    global = {
      envFrom = [
        { secretRef = { name = "authentik-env-secrets" } }
      ]
    }
    authentik = {
      error_reporting = { enabled = true }

      postgresql = {
        host         = "cloudnative-pg-database-cluster-pooler-rw.cloudnative-pg-database"
        name         = "authentik"
        port         = 5432
        conn_max_age = 60

        read_replicas = [
          {
            host         = "cloudnative-pg-database-cluster-pooler-ro.cloudnative-pg-database"
            name         = "authentik"
            port         = 5432
            conn_max_age = 60
          }
        ]
      }

      email = {
        host         = "smtp.fastmail.com"
        port         = 465
        conn_max_age = 60
        username     = "ramona@luczkiewi.cz"
        use_ssl      = true
        from         = "roboramona <roboramona@luczkiewi.cz>"
      }
    }
    server = {
      replicas = 2
      metrics  = { enabled = true, serviceMonitor = { enabled = true } }
      route = {
        main = {
          enabled    = true
          hostnames  = ["account.ramona.fun"]
          parentRefs = [{ name = "gateway-public", namespace = "kgateway-system" }]
        }
      }
    }
    worker = {
      replicas = 2
      metrics  = { enabled = true, serviceMonitor = { enabled = true } }
    }
    prometheus = { rules = { enabled = true } }
  })]
}
