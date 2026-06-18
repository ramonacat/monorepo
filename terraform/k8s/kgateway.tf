resource "helm_release" "kgateway-crds" {
  name             = "kgateway-crds"
  chart            = "oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds"
  namespace        = "kgateway-system"
  create_namespace = true
  version          = "2.3.3"
}

resource "helm_release" "kgateway" {
  name             = "kgateway"
  chart            = "oci://cr.kgateway.dev/kgateway-dev/charts/kgateway"
  namespace        = helm_release.kgateway-crds.namespace
  create_namespace = true
  version          = "2.3.4"

  values = [yamlencode({
    controller = {
      replicaCount = 2
    }
  })]
}
