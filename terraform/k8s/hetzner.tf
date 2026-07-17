resource "kubernetes_secret_v1" "hcloud" {
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }

  data = {
    token   = var.hcloud_token
    network = var.network_id
  }
}

resource "helm_release" "hcloud-cloud-controller-manager" {
  name       = "hccm"
  chart      = "hcloud-cloud-controller-manager"
  repository = "https://charts.hetzner.cloud"
  namespace  = "kube-system"
  version    = "1.34.0"

  values = [yamlencode({
    replicaCount = 2
    networking = {
      enabled     = true
      clusterCIDR = var.pod_cidr
    }
  })]
}

resource "helm_release" "hcloud-csi" {
  name       = "hcloud-csi"
  chart      = "hcloud-csi"
  repository = "https://charts.hetzner.cloud"
  namespace  = "kube-system"
  version    = "2.22.0"

  values = [yamlencode({
    storageClasses = [
      {
        name                = "hcloud-volumes"
        defaultStorageClass = false
        reclaimPolicy       = "Delete"
      }
    ]
  })]
}
