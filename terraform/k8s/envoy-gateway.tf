// this needs a manual deployment because the CRDs are big and helm doesn't do server-side apply
// https://gateway.envoyproxy.io/docs/install/install-helm/#installing-crds-separately
// commented out because helm tries (and fails) to create a secret with the deployment information at the end
/* resource "helm_release" "envoy-gateway-crds" {
  name             = "envoy-gateway-crds"
  chart            = "oci://docker.io/envoyproxy/gateway-crds-helm"
  namespace        = "envoy-gateway-system"
  create_namespace = true
  version          = "1.8.2"

  values = [yamlencode({
    crds = {
      envoyGateway = { enabled = true }
    }
  })]
}*/

resource "helm_release" "envoy-gateway" {
  name             = "envoy-gateway"
  chart            = "oci://docker.io/envoyproxy/gateway-helm"
  namespace        = "envoy-gateway-system"
  create_namespace = true
  version          = "1.8.2"

  values = [yamlencode({
    crds = { enabled = false }
    podDisruptionBudget = {
      minAvailable = 1
    }
    deployment = {
      replicas = 2
    }
  })]
}
