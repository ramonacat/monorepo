resource "helm_release" "velero" {
  name             = "velero"
  chart            = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  version          = "12.1.0"
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
        bucket   = "ramona-kubernetes-darkmore-backups"
        default  = true
        config = {
          region = "nbg1"
          s3Url  = "https://nbg1.your-objectstorage.com"
        }
      }]
      volumeSnapshotLocation = [{
        name     = "default"
        provider = "csi"
      }]
      logFormat               = "json"
      features                = "EnableCSI"
      defaultSnapshotMoveData = true

    }
    credentials = {
      existingSecret = "object-storage"
    }
    schedules = {
      default = {
        schedule         = "0 */3 * * *"
        snapshotMoveData = true
        template = {
          includedNamespaces = ["*"]
          excludedNamespaces = [
            helm_release.longhorn.namespace,
            helm_release.kube-prometheus-stack.namespace,
            helm_release.cloudnative-pg-database.namespace,
            "velero"
          ]
        }
      }
    }
    metrics = {
      serviceMonitor      = { enabled = true }
      nodeAgentPodMonitor = { enabled = true }
      prometheusRule      = { enabled = true }
    }
  })]
}
