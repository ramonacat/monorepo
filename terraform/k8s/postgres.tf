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
        create    = var.create_grafana_dashboards
        namespace = "grafana"
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
      instances = 3
      storage   = { size = "20Gi", storageClass = "hcloud-volumes" }
      monitoring = {
        enabled = true
      }
      roles = [
        {
          name           = "crowdsec"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "crowdsec" }
        },
        {
          name           = "fluentbit"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "fluentbit" }
        },
        // TODO the following roles should be coming from an argument probably
        {
          name           = "grafana"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "grafana" }
          inRoles        = ["fluentbit"]
        },
        {
          name           = "authentik"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "authentik" }
        },
      ]
    }
    databases = [
      {
        name   = "crowdsec"
        owner  = "crowdsec"
        ensure = "present"
      },
      {
        name   = "fluentbit"
        owner  = "fluentbit"
        ensure = "present"
      },
      // TODO the following databases should be coming from an argument probably
      {
        name   = "authentik"
        owner  = "authentik"
        ensure = "present"
      },
    ]
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
