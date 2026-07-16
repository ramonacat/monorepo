resource "helm_release" "coredns" {
  name       = "coredns"
  chart      = "coredns"
  repository = "https://coredns.github.io/helm"
  namespace  = "kube-system"
  version    = "1.46.1"

  values = [yamlencode({
    replicaCount = 3
    // https://github.com/coredns/helm/blob/master/charts/coredns/README.md#adopting-existing-coredns-resources
    k8sAppLabelOverride : "kube-dns"
    prometheus = {
      service = { enabled = true }
      monitor = { enabled = true }
    }
  })]
}

