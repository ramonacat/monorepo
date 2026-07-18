resource "tls_private_key" "vault-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "vault-oidc" {
  private_key_pem = tls_private_key.vault-oidc.private_key_pem

  subject {
    common_name = "vault authentik"
  }

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "authentik_certificate_key_pair" "vault-oidc" {
  name             = "vault-oidc"
  certificate_data = tls_self_signed_cert.vault-oidc.cert_pem
  key_data         = tls_private_key.vault-oidc.private_key_pem
}

resource "authentik_provider_oauth2" "vault" {
  name               = "vault"
  client_id          = "vault"
  authorization_flow = authentik_flow.default-provider-authorization-implicit-consent.uuid
  invalidation_flow  = authentik_flow.default-provider-invalidation.uuid
  grant_types        = ["authorization_code"]
  signing_key        = authentik_certificate_key_pair.vault-oidc.id

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://vault.internal.ramona.fun/ui/vault/auth/oidc/oidc/callback"
      redirect_uri_type = "authorization"
    },
    {
      matching_mode     = "strict",
      url               = "https://vault.internal.ramona.fun/v1/auth/oidc/oidc/callback"
      redirect_uri_type = "authorization"
    },
    {
      matching_mode     = "strict",
      url               = "http://localhost:8250/oidc/callback"
      redirect_uri_type = "authorization"
    },
  ]
}

data "authentik_provider_oauth2_config" "vault" {
  provider_id = authentik_provider_oauth2.vault.id
}

resource "authentik_application" "vault" {
  name              = "vault"
  slug              = "vault"
  protocol_provider = authentik_provider_oauth2.vault.id
}

resource "authentik_policy_binding" "vault-global-admins" {
  order  = 0
  target = authentik_application.vault.uuid
  group  = authentik_group.global-admins.id
}

resource "authentik_application_entitlement" "vault" {
  name        = "vault"
  application = authentik_application.vault.uuid
}

resource "authentik_policy_binding" "vault" {
  target = authentik_application_entitlement.vault.id
  group  = authentik_group.global-admins.id
  order  = 0
}

resource "vault_policy" "admin" {
  name   = "admin"
  policy = <<-EOT
    path "*" {
      capabilities = ["create", "read", "update", "patch", "delete", "list", "recover", "sudo"]
    }
  EOT
}

resource "vault_jwt_auth_backend_role" "admin" {
  backend        = "oidc"
  role_name      = "admin"
  token_policies = [vault_policy.admin.name]
  user_claim     = "sub"
  allowed_redirect_uris = [
    "https://vault.internal.ramona.fun/ui/vault/auth/oidc/oidc/callback",
    "https://vault.internal.ramona.fun/v1/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
}

resource "vault_jwt_auth_backend" "authentik" {
  path         = "oidc"
  default_role = vault_jwt_auth_backend_role.admin.role_name

  oidc_discovery_url = data.authentik_provider_oauth2_config.vault.issuer_url
  oidc_client_id     = authentik_provider_oauth2.vault.client_id
  oidc_client_secret = authentik_provider_oauth2.vault.client_secret
}

resource "vault_auth_backend" "cert" {
  path = "cert"
  type = "cert"
}

resource "vault_policy" "cert-self-issue" {
  name   = "cert-self-issue"
  policy = <<-EOT
    path "/pki-hosts/issue/hosts" {
      capabilities = ["create", "patch", "read", "update"]
    }
  EOT
}

resource "vault_cert_auth_backend_role" "hosts" {
  name           = "hosts"
  certificate    = module.pki-hosts.certificate
  backend        = vault_auth_backend.cert.path
  ocsp_enabled   = false
  token_policies = ["default", vault_policy.cert-self-issue.name]
}
