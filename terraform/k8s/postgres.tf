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

  lifecycle_rules {
    file_name_prefix                                       = ""
    days_from_hiding_to_deleting                           = 1
    days_from_starting_to_canceling_unfinished_large_files = 1
  }
}

resource "helm_release" "cloudnative-pg-barman-plugin" {
  name             = "cloudnative-pg-plugin-barman-cloud"
  chart            = "plugin-barman-cloud"
  repository       = "https://cloudnative-pg.github.io/charts"
  namespace        = "cloudnative-pg"
  create_namespace = true
  version          = "0.7.0"
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
      enabled             = true
      method              = "plugin"
      endpointURL         = "https://s3.us-west-002.backblazeb2.com"
      provider            = "s3"
      pluginConfiguration = { name = "barman-cloud.cloudnative-pg.io" }
      s3 = {
        region = "nbg1"
        bucket = "ramona-kubernetes-darkmore-postgres-backups"
      }
      wal  = { maxParallel = 32 }
      data = { jobs = 32 }
      scheduledBackups = [
        {
          name                 = "daily"
          schedule             = "0 0 0 * * *"
          backupOwnerReference = "self"
          method               = "plugin"
          pluginConfiguration  = { name = "barman-cloud.cloudnative-pg.io" }
        }
      ]
      secret = { create = false, name = "cloudnative-pg-database-cluster-backup-s3-creds" }
      instanceSidecarConfiguration = {
        env = [
          { name = "AWS_REQUEST_CHECKSUM_CALCULATION", value = "when_required" },
          { name = "AWS_RESPONSE_CHECKSUM_VALIDATION", value = "when_required" },
        ]
      }
    }
    cluster = {
      instances = 3
      storage   = { size = "20Gi", storageClass = "hcloud-volumes" }
      monitoring = {
        enabled = true
      }
      plugins = [
        {
          name          = "barman-cloud.cloudnative-pg.io"
          enabled       = true
          isWALArchiver = true
        }
      ]
      roles = [
        {
          name           = "fluentbit"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "fluentbit" }
        },
        // TODO the following roles should be deployed via argo or something
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
        },
        {
          name           = "attic"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "attic" }
        },
        {
          name           = "red-proxy"
          ensure         = "present"
          login          = true
          passwordSecret = { name = "red-proxy" }
        }
      ]
    }
    databases = [
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
      },
      {
        name   = "attic"
        owner  = "attic"
        ensure = "present"
      },
      {
        name   = "red-proxy"
        owner  = "red-proxy"
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
}
