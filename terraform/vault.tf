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
      capabilities = ["create", "patch", "read"]
      allowed_parameters = {
        "common_name" = ["{{identity.entity.aliases.${vault_auth_backend.cert.accessor}.metadata.common_name}}"]
        "ttl" = []
      }
    }
  EOT
}

resource "vault_cert_auth_backend_role" "hosts" {
  name           = "hosts"
  certificate    = vault_pki_secret_backend_intermediate_set_signed.hosts.certificate
  backend        = vault_auth_backend.cert.path
  ocsp_enabled   = true
  token_policies = []
}

resource "vault_auth_backend" "kubernetes" {
  path = "kubernetes"
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "main" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://kubernetes.default"
  issuer             = "https://kubernetes.default.svc.cluster.local"
  kubernetes_ca_cert = <<-EOT
  -----BEGIN CERTIFICATE-----
  MIIDBTCCAe2gAwIBAgIIQCsq1LiE4cUwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
  AxMKa3ViZXJuZXRlczAeFw0yNjA2MTgxNzA2NTBaFw0zNjA2MTUxNzExNTBaMBUx
  EzARBgNVBAMTCmt1YmVybmV0ZXMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
  AoIBAQDRiO5vikNkyotk0DatfUJY7t0eZ/WkdsDtS+RuYJ2wb4jfhiAtVsVpRtnR
  FwJBCiK4aQ34N34a+VBuPxOaIIaEkufGwvkBriKGukNTA9nfhMTmClBjRVboZK4H
  HruLcX8n9/O6S505T7RY9UD9nIqDpatXrt3jKh7xWqWHUI4dJrNnRAEBKasnqT3I
  58vnVd1gL8I1514Q6iFIIEgaqWFx8Nj0k2blO3sUgCsnwailj9AFA0+Z9pIRJceg
  nZmKL9q7JqE7fb5sMs7j9Q1Qv1JWSvmsOqEjzGezXJu6+fnr50h5anpj6M25lk+n
  9scdHuWvHfjTyz0uXZdisB8tFzbPAgMBAAGjWTBXMA4GA1UdDwEB/wQEAwICpDAP
  BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBSMjGrFUqk46fy6k3O8mgrSZm5/LDAV
  BgNVHREEDjAMggprdWJlcm5ldGVzMA0GCSqGSIb3DQEBCwUAA4IBAQAacdU7rHXr
  gf+UKXylk41CIu+Ucjf9a5TPLkQgf4NcOmIXNxOHvUZ0v5Ier3X/CjztLI0LSvxc
  Anp6JYLclaVj+8JHSb0kCmc3rM7XkeI+glRdqyW4ymlMqDEqUTodHuxC3NzrtYwf
  22NPkPLAELyJpaWX6MRy/5Plk6nKUNbkpMBwimAt5/EVCDnC+f0Hzx2FB6FMSbMW
  7Ui0C3SV5WrRwLCMFvXviBpWKiTK9UQZDTCpbLP2dCS9NDnTyH8BppjcaTarQcKW
  iRr9oho1+LCFSV8vSbSsHlpTvkC7VB2t8D3WaDIvi9hVtsCgXs3UYClMCs/x4/w8
  KYGq/F/7w2rz
  -----END CERTIFICATE-----
  EOT
}

resource "vault_policy" "cert-self-issue-any-internal" {
  name   = "cert-self-issue-internal"
  policy = <<-EOT
    path "/pki-internal/sign/internal" {
      capabilities = ["create", "patch", "read", "update"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "cert-manager" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cert-manager"
  bound_service_account_names      = ["vault-issuer"]
  bound_service_account_namespaces = ["vault"]
  token_policies                   = ["default", vault_policy.cert-self-issue-any-internal.name]
  audience                         = "vault://vault/vault-self-issuer"
}
