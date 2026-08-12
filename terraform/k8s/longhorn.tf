resource "helm_release" "longhorn" {
  name             = "longhorn"
  chart            = "longhorn"
  repository       = "https://charts.longhorn.io"
  namespace        = "longhorn-system"
  create_namespace = true
  version          = "1.12.0"

  values = [yamlencode({
    httproute = {
      enabled    = true
      hostnames  = ["longhorn.infrastructure.ramona.fun"]
      parentRefs = [{ name = "gateway-tailscale", namespace = "kgateway-system" }]
    }
    metrics = {
      serviceMonitor = { enabled = true }
    }
    longhornManager = {
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "0.05"
        }
        limits = {
          memory = "512Mi"
          cpu    = "0.2"
        }
      }
    }
    longhornUI = {
      podDisruptionBudget = { enabled = true }
    }
    defaultSettings = {
      replicaAutoBalance                = true
      storageOverProvisioningPercentage = 100
      rwxVolumeFastFailover             = true
      systemManagedCSIComponentsResourceLimits = {
        csi-attacher = {
          requests = {
            memory = "64Mi"
            cpu    = "0.01"
          }
          limits = {
            memory = "128Mi"
            cpu    = "0.05"
          }
        }
        csi-provisioner = {
          requests = {
            memory = "64Mi"
            cpu    = "0.01"
          }
          limits = {
            memory = "128Mi"
            cpu    = "0.05"
          }
        }
        csi-resizer = {
          requests = {
            memory = "64Mi"
            cpu    = "0.01"
          }
          limits = {
            memory = "128Mi"
            cpu    = "0.05"
          }
        }
        csi-snapshotter = {
          requests = {
            memory = "64Mi"
            cpu    = "0.01"
          }
          limits = {
            memory = "128Mi"
            cpu    = "0.05"
          }
        }
        longhorn-csi-plugin = {
          requests = {
            memory = "128Mi"
            cpu    = "0.01"
          }
          limits = {
            memory = "192Mi"
            cpu    = "0.05"
          }
        }
      }
    }
  })]
}
