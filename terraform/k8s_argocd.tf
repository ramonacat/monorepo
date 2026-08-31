resource "tls_private_key" "argocd-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "argocd-oidc" {
  private_key_pem = tls_private_key.argocd-oidc.private_key_pem

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  subject {
    common_name = "argocd authentik"
  }
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
  provider_id = authentik_provider_oauth2.argocd.id

  depends_on = [authentik_application.argocd]
}

resource "authentik_policy_binding" "argocd-global-admins" {
  order  = 0
  target = authentik_application.argocd.uuid
  group  = authentik_group.global-admins.id
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
  version          = "10.4.2"

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
        "kustomize.buildOptions" = "--enable-helm"
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
      ssh = {
        extraHosts = <<-EOT
          code.ramona.fun ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcNmDrVqqyJcASo3q1z5+EnosFL9xHUgp4AhbGjeJ0OLhoD+zszr1+QZwrQAX1oYRq7qr3Jz9xvetJRTmt8kEohuTmlwe47B/m1hYHHq5nWMuPGbY6AaYinKtiOqiBnopTr5DzRQdm4MEHiTMSXJ1VC3e4ATBfHkNB9iFLJjqrEPdzjZC5wx2nI1SA98AUwX83cWi15fxDVS6H68yBADnFPHbc6xOUwPxORRjh0nAnDJQBZCGt54z9qx7R6tjPm0D5Dp9G46OKLHjBJpnKEje4ALU0dfV3WBf3n0LKp5p0sNKRUEooosqGE28DpirQK9TforLJvu1S0OQTGEcKacR198jlSlY5qCWOekgCEj5xN3AKtZE+WZCVuQQD7O3/boht1y4OUfpvC+e5pe/XIiigQZZ/5sMN2JeDkuNef3q6n0kJhVwtCJpRdhFGinE9uuXOoyPWn5zQgKdosYFfYWjQzM0xtOuIPXxfgRfdmy+St/78ISEDfujPGZoZSnVNc2FF/h6P4XhC7+QgAeDqutFYHnS6A5/GwE9PoSAk+qlH8nBAVllKxsMLwQu9zoV5PilLeumlYDTPAqY6V24Ti0Pn7Tgn0JIs4t+hCXlwCxy1RAezcPs6i/BazAVGeiwrFQuhQ4AcNppVJdOuoMfMjJoCP7NpSkVdKX/thMs9evIlMw==
        EOT
      }
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
