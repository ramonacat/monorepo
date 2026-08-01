resource "tls_private_key" "api-public-test-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "api-public-test-oidc" {
  private_key_pem = tls_private_key.api-public-test-oidc.private_key_pem

  subject {
    common_name = "api-public-test authentik"
  }

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "authentik_certificate_key_pair" "api-public-test-oidc" {
  name             = "api-public-test-oidc"
  certificate_data = tls_self_signed_cert.api-public-test-oidc.cert_pem
  key_data         = tls_private_key.api-public-test-oidc.private_key_pem
}

resource "authentik_provider_oauth2" "api-public-test" {
  name               = "api-public-test"
  client_id          = "api-public-test"
  authorization_flow = authentik_flow.default-provider-authorization-implicit-consent.uuid
  invalidation_flow  = authentik_flow.default-provider-invalidation.uuid
  grant_types        = ["authorization_code"]
  signing_key        = authentik_certificate_key_pair.api-public-test-oidc.id
  property_mappings = [
    authentik_property_mapping_provider_scope.entitlements.id
  ]

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "http://test.ramona.fun:3000/authorize"
      redirect_uri_type = "authorization"
    },
  ]
}

data "authentik_provider_oauth2_config" "api-public-test" {
  provider_id = authentik_provider_oauth2.api-public-test.id
}

resource "authentik_application" "api-public-test" {
  name              = "api-public-test"
  slug              = "api-public-test"
  protocol_provider = authentik_provider_oauth2.api-public-test.id
}

resource "authentik_policy_binding" "api-public-test-global-admins" {
  order  = 0
  target = authentik_application.api-public-test.uuid
  group  = authentik_group.global-admins.id
}

output "api-public-test-client-id" {
  value = authentik_provider_oauth2.api-public-test.client_id
}

output "api-public-test-client-secret" {
  value     = authentik_provider_oauth2.api-public-test.client_secret
  sensitive = true
}

output "api-public-test-client-issuer-url" {
  value = data.authentik_provider_oauth2_config.api-public-test.issuer_url
}

resource "authentik_application_entitlement" "api-public-test--admin" {
  name        = "admin"
  application = authentik_application.api-public-test.uuid
}

resource "authentik_policy_binding" "global-admins--api-public-test--admin" {
  order  = 0
  target = authentik_application_entitlement.api-public-test--admin.id
  group  = authentik_group.global-admins.id
}

resource "vault_kv_secret_v2" "api-public-test--oauth" {
  mount = "secrets/kubernetes/darkmore"
  name  = "api-public-test/oauth"
  data_json = jsonencode({
    DOCS_OAUTH_CLIENT_ID     = authentik_provider_oauth2.api-public-test.client_id
    DOCS_OAUTH_CLIENT_SECRET = authentik_provider_oauth2.api-public-test.client_secret
    DOCS_OIDC_ISSUER_URL     = data.authentik_provider_oauth2_config.api-public-test.issuer_url
  })
}
