resource "helm_release" "kgateway-crds" {
  name             = "kgateway-crds"
  chart            = "oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds"
  namespace        = "kgateway-system"
  create_namespace = true
  version          = "2.4.0"
}

resource "helm_release" "kgateway" {
  name             = "kgateway"
  chart            = "oci://cr.kgateway.dev/kgateway-dev/charts/kgateway"
  namespace        = helm_release.kgateway-crds.namespace
  create_namespace = true
  version          = "2.3.6"

  values = [yamlencode({
    controller = {
      replicaCount   = 2
      serviceMonitor = { enabled = true }
    }
  })]
}

resource "helm_release" "envoy-proxy-crowdsec-bouncer" {
  name             = "envoy-proxy-crowdsec-bouncer"
  chart            = "oci://ghcr.io/kdwils/charts/envoy-proxy-bouncer"
  namespace        = "kgateway-system"
  create_namespace = true
  version          = "0.6.3"

  values = [yamlencode({
    replicaCount = 2
    config = {
      bouncer = {
        lapiURL = "http://crowdsec-service.crowdsec:8080"
        metrics = true
        apiKeySecretRef = {
          name = "crowdsec-api-key"
          key  = "ENVOY_BOUNCER_BOUNCER_APIKEY"
        }
      }
      prometheus = { enabled = true, serviceMonitor = { enabled = true } }
    }
  })]
}
