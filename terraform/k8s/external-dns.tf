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
  version    = "1.22.0"

  values = [yamlencode({
    serviceMonitor = {
      enabled = true
    }
    sources                   = ["gateway-httproute", "gateway-tcproute", "gateway-tlsroute", "gateway-grpcroute", "gateway-udproute"]
    excludeDomains            = ["ts.net"]
    policy                    = "sync"
    enableGatewayListenerSets = true
    logFormat                 = "json"
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
