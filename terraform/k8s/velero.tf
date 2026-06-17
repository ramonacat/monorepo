resource "b2_bucket" "backups" {
  bucket_name = "ramona-kubernetes-${var.name}-backups"
  bucket_type = "allPrivate"
}

resource "b2_application_key" "backups" {
  key_name     = "kubernetes-${var.name}-backups"
  capabilities = ["deleteFiles", "listBuckets", "listFiles", "readBucketEncryption", "readBuckets", "readFiles", "shareFiles", "writeBucketEncryption", "writeFiles"]
  bucket_ids   = [b2_bucket.backups.bucket_id]
}

data "b2_account_info" "account" {
}

locals {
  // the b2 provider does not allow us to get the region, so I guess this is better than hardcoding maybe?
  b2_account_region = regex("^.+://s3\\.(?P<region>.+)\\.backblaze.*", data.b2_account_info.account.s3_api_url).region
}

resource "helm_release" "velero" {
  name             = "velero"
  chart            = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  version          = "v12.0.3"
  namespace        = "velero"
  create_namespace = true

  values = [yamlencode({
    deployNodeAgent = true
    initContainers = [
      {
        name         = "velero-plugin-for-aws"
        image        = "velero/velero-plugin-for-aws:v1.13.2"
        volumeMounts = [{ mountPath = "/target", name = "plugins" }]
      }
    ]
    configuration = {
      backupStorageLocation = [{
        name     = "default"
        provider = "aws"
        bucket   = b2_bucket.backups.bucket_name
        default  = true
        config = {
          region = local.b2_account_region
          s3Url  = data.b2_account_info.account.s3_api_url
        }
      }]
      volumeSnapshotLocation = [{
        name     = "default"
        provider = "csi"
      }]
      features                = "EnableCSI"
      defaultSnapshotMoveData = true
    }
    schedules = {
      default = {
        schedule         = "0 */3 * * *"
        snapshotMoveData = true
        template = {
          includedNamespaces = ["*"]
          excludedNamespaces = [helm_release.rook-ceph.namespace, helm_release.rook-ceph-cluster.namespace]
        }
      }
    }
  })]

  set_sensitive = [
    {
      name  = "credentials.secretContents.cloud",
      value = <<EOT
      [default]
      aws_access_key_id=${b2_application_key.backups.application_key_id}
      aws_secret_access_key=${b2_application_key.backups.application_key}
      EOT
    }
  ]
}
