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

resource "helm_release" "cert-manager-webhook-dnsimple" {
  name       = "cert-manager-webhook-dnsimple"
  chart      = "cert-manager-webhook-dnsimple"
  repository = "https://puzzle.github.io/cert-manager-webhook-dnsimple"
  namespace  = helm_release.cert-manager.namespace

  values = [yamlencode({
    clusterIssuer = {
      email      = "ramona@luczkiewi.cz"
      production = { enabled = true }
      staging    = { enabled = true }
    }
  })]

  set_sensitive = [
    {
      name  = "dnsimple.token",
      value = var.dnsimple_token
    }
  ]
}
