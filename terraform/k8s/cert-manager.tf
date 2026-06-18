resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  chart            = "oci://quay.io/jetstack/charts/cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.20.2"

  values = [yamlencode({
    crds                      = { enabled = true }
    replicaCount              = 2
    enableCertificateOwnerRef = true
    prometheus                = { servicemonitor = { enabled = true } }
    webhook                   = { replicaCount = 2 }
    config                    = { enableGatewayAPI = true }
  })]
}
