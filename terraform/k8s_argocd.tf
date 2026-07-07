resource "tls_private_key" "argocd-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "argocd-oidc" {
  private_key_pem = tls_private_key.argocd-oidc.private_key_pem

  subject {
    common_name = "argocd authentik"
  }

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "authentik_certificate_key_pair" "argocd-oidc" {
  name             = "argocd-oidc"
  certificate_data = tls_self_signed_cert.argocd-oidc.cert_pem
  key_data         = tls_private_key.argocd-oidc.private_key_pem
}

resource "authentik_provider_oauth2" "argocd" {
  name               = "argocd"
  client_id          = "argocd"
  authorization_flow = authentik_flow.default-provider-authorization-implicit-consent.uuid
  invalidation_flow  = authentik_flow.default-provider-invalidation.uuid
  grant_types        = ["authorization_code"]
  signing_key        = authentik_certificate_key_pair.argocd-oidc.id
  property_mappings = [
    authentik_property_mapping_provider_scope.email.id,
    authentik_property_mapping_provider_scope.profile.id
  ]

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://argo-cd.infrastructure.ramona.fun/api/dex/callback"
      redirect_uri_type = "authorization"
    },
    {
      matching_mode     = "strict",
      url               = "https://localhost:8085/auth/callback"
      redirect_uri_type = "authorization"
    },
    {
      matching_mode     = "strict",
      url               = "https://argo-cd.infrastructure.ramona.fun/applications"
      redirect_uri_type = "authorization"
    },
  ]
}

data "authentik_provider_oauth2_config" "argocd" {
  depends_on  = [authentik_application.argocd]
  provider_id = authentik_provider_oauth2.argocd.id
}

resource "authentik_application" "argocd" {
  name              = "argocd"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id
}

resource "helm_release" "argo-cd" {
  name             = "argo-cd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argo-cd"
  create_namespace = true
  version          = "10.1.2"

  values = [yamlencode({
    global = {
      domain                   = "argo-cd.ibis-draconis.ts.net"
      addPrometheusAnnotations = true
      logging                  = { format = "json" }
    },
    configs = {
      cm = {
        "url"                = "https://argo-cd.infrastructure.ramona.fun"
        "accounts.terraform" = "apiKey"
        "dex.config" = yamlencode({
          connectors = [
            {
              config = {
                issuer               = data.authentik_provider_oauth2_config.argocd.issuer_url
                clientID             = authentik_provider_oauth2.argocd.client_id
                clientSecret         = "$oauth2_client_secret"
                insecureEnableGroups = true
                scopes               = ["openid", "profile", "email"]
              }
              name = "authentik"
              type = "oidc"
              id   = "authentik"
            }
          ]
        })
      },
      params = {
        "server.insecure" = true
      },
      rbac = {
        "policy.csv" = <<-EOT
        g, terraform, role:admin
        g, ${authentik_group.global-admins.name}, role:admin
        EOT
      },
    },
    redis-ha = {
      enabled          = true,
      hardAntiAffinity = false,
      replicas         = 3,
      haproxy = {
        replicas         = 2,
        hardAntiAffinity = false
        metrics          = { enabled = true, serviceMonitor = { enabled = true } }
      },
      exporter = {
        enabled        = true,
        serviceMonitor = { enabled = true }
      }
    },
    controller = {
      replicas = 1,
      metrics = {
        enabled        = true
        serviceMonitor = { enabled = true }
      }
    },
    server = {
      replicas = 2
      httproute = {
        enabled   = true
        hostnames = ["argo-cd.infrastructure.ramona.fun"]
        parentRefs = [
          { name = "gateway-tailscale", namespace = "kgateway-system" }
        ]
      }
      metrics = {
        enabled        = true
        serviceMonitor = { enabled = true }
      }
    },
    repoServer = {
      replicas = 2
      metrics = {
        enabled        = true
        serviceMonitor = { enabled = true }
      }
    },
    applicationSet = {
      replicas = 2
      metrics = {
        enabled        = true
        serviceMonitor = { enabled = true }
      }
    },
  })]

  set_sensitive = [{
    name  = "configs.secret.extra.oauth2_client_secret"
    value = authentik_provider_oauth2.argocd.client_secret
  }]
}
