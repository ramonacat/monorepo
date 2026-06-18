resource "kubernetes_namespace_v1" "external-dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_secret_v1" "dnsimple" {
  metadata {
    name      = "dnsimple-token"
    namespace = kubernetes_namespace_v1.external-dns.metadata[0].name
  }

  data = {
    token = var.dnsimple_token
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  namespace  = kubernetes_namespace_v1.external-dns.metadata[0].name
  version    = "v1.21.1"

  values = [yamlencode({
    serviceMonitor = {
      enabled = true
    }
    sources        = ["service", "ingress", "gateway-httproute"]
    excludeDomains = ["ts.net"]
    provider = {
      name = "dnsimple"
    }
    env = [
      {
        name = "DNSIMPLE_OAUTH"
        valueFrom = {
          secretKeyRef = {
            name = kubernetes_secret_v1.dnsimple.metadata[0].name
            key  = "token"
          }
        }
      }
    ]
  })]
}
