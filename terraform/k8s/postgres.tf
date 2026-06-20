resource "helm_release" "cloudnative-pg" {
  name             = "cloudnative-pg"
  chart            = "cloudnative-pg"
  repository       = "https://cloudnative-pg.github.io/charts"
  namespace        = "cloudnative-pg"
  create_namespace = true
  version          = "0.28.3"

  values = [yamlencode({
    monitoring = {
      podMonitorEnabled = true
      grafanaDashboard = {
        // TODO this should come from a var
        create = true
      }
    }
  })]
}

resource "helm_release" "cloudnative-pg-database" {
  name             = "cloudnative-pg-database"
  chart            = "cluster"
  repository       = "https://cloudnative-pg.github.io/charts"
  namespace        = "cloudnative-pg-database"
  create_namespace = true
  version          = "0.7.0"

  values = [yamlencode({
    cluster = {
      instances = 2
      storage   = { size = "1Gi" }
      monitoring = {
        enabled = true
      }
    }
    poolers = [
      {
        name       = "rw"
        type       = "rw"
        poolMode   = "session"
        instances  = 2
        monitoring = { enabled = true }
      },
      {
        name       = "ro"
        type       = "ro"
        poolMode   = "session"
        instances  = 2
        monitoring = { enabled = true }
      }
    ]
  })]
}
