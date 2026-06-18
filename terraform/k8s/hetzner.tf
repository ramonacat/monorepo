resource "kubernetes_namespace_v1" "hcloud-cloud-controller-manager" {
  metadata {
    name = "hcloud-cloud-controller-manager"
  }
}

resource "kubernetes_secret_v1" "hcloud" {
  metadata {
    name      = "hcloud"
    namespace = kubernetes_namespace_v1.hcloud-cloud-controller-manager.metadata[0].name
  }

  data = {
    token   = var.hcloud_token
    network = var.network_id
  }
}

resource "helm_release" "hcloud-cloud-controller-manager" {
  name       = "hcloud-cloud-controller-manager"
  chart      = "hcloud-cloud-controller-manager"
  repository = "https://charts.hetzner.cloud"
  namespace  = kubernetes_namespace_v1.hcloud-cloud-controller-manager.metadata[0].name
  version    = "v1.32.0"

  values = [yamlencode({
    replicaCount = 2
    networking = {
      enabled     = true
      clusterCIDR = var.pod_cidr
    }
  })]
}
