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
    sources        = ["gateway-httproute"]
    excludeDomains = ["ts.net"]
    // TODO: AAAA is disabled because of https://github.com/kubernetes-sigs/external-dns/issues/6511
    managedRecordTypes = ["A", "CNAME"]
    logFormat          = "json"
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
