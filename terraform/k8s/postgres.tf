resource "helm_release" "cloudnative-pg" {
  name             = "cloudnative-pg"
  chart            = "cloudnative-pg"
  repository       = "https://cloudnative-pg.github.io/charts"
  namespace        = "cloudnative-pg"
  create_namespace = true
  version          = "0.29.0"

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

resource "b2_bucket" "cloudnative-pg-backups" {
  bucket_name = "ramona-kubernetes-${var.name}-postgres-backups"
  bucket_type = "allPrivate"
}

resource "b2_application_key" "cloudnative-pg-backups" {
  key_name     = "kubernetes-${var.name}-postgres-backups"
  capabilities = ["deleteFiles", "listBuckets", "listFiles", "readBucketEncryption", "readBuckets", "readFiles", "shareFiles", "writeBucketEncryption", "writeFiles"]
  bucket_ids   = [b2_bucket.cloudnative-pg-backups.bucket_id]
}

resource "helm_release" "cloudnative-pg-database" {
  name             = "cloudnative-pg-database"
  chart            = "cluster"
  repository       = "https://cloudnative-pg.github.io/charts"
  namespace        = "cloudnative-pg-database"
  create_namespace = true
  version          = "0.8.1"

  values = [yamlencode({
    version = { postgresql = "18" }
    backups = {
      enabled     = true
      endpointURL = data.b2_account_info.account.s3_api_url
      provider    = "s3"
      s3 = {
        region = local.b2_account_region
        bucket = b2_bucket.cloudnative-pg-backups.bucket_name
      }
    }
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
        {
          name           = "ras"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "ras" }
        }
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
      {
        name   = "ras"
        owner  = "ras"
        ensure = "present"
      }
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

  set_sensitive = [
    { name = "backups.s3.accessKey", value = b2_application_key.cloudnative-pg-backups.application_key_id },
    { name = "backups.s3.secretKey", value = b2_application_key.cloudnative-pg-backups.application_key }
  ]
}
