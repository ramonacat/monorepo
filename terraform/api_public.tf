resource "tls_private_key" "api-public-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "api-public-oidc" {
  private_key_pem = tls_private_key.api-public-oidc.private_key_pem

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  subject {
    common_name = "api-public authentik"
  }
}

resource "authentik_certificate_key_pair" "api-public-oidc" {
  name             = "api-public-oidc"
  certificate_data = tls_self_signed_cert.api-public-oidc.cert_pem
  key_data         = tls_private_key.api-public-oidc.private_key_pem
}

resource "authentik_provider_oauth2" "api-public" {
  name               = "api-public"
  client_id          = "api-public"
  authorization_flow = authentik_flow.default-provider-authorization-implicit-consent.uuid
  invalidation_flow  = authentik_flow.default-provider-invalidation.uuid
  grant_types        = ["authorization_code"]
  signing_key        = authentik_certificate_key_pair.api-public-oidc.id
  property_mappings = [
    authentik_property_mapping_provider_scope.entitlements.id
  ]

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://red-proxy.ramona.fun/authorize"
      redirect_uri_type = "authorization"
    },
  ]
}

data "authentik_provider_oauth2_config" "api-public" {
  provider_id = authentik_provider_oauth2.api-public.id
}

resource "authentik_application" "api-public" {
  name              = "api-public"
  slug              = "api-public"
  protocol_provider = authentik_provider_oauth2.api-public.id
}

resource "authentik_policy_binding" "api-public-global-admins" {
  order  = 0
  target = authentik_application.api-public.uuid
  group  = authentik_group.global-admins.id
}

resource "authentik_application_entitlement" "api-public--admin" {
  name        = "admin"
  application = authentik_application.api-public.uuid
}

resource "authentik_policy_binding" "global-admins--api-public--admin" {
  order  = 0
  target = authentik_application_entitlement.api-public--admin.id
  group  = authentik_group.global-admins.id
}

resource "vault_kv_secret_v2" "api-public--oauth" {
  mount = "secrets/kubernetes/darkmore"
  name  = "api-public/oauth"
  data_json = jsonencode({
    OAUTH_CLIENT_ID     = authentik_provider_oauth2.api-public.client_id
    OAUTH_CLIENT_SECRET = authentik_provider_oauth2.api-public.client_secret
    OIDC_ISSUER_URL     = data.authentik_provider_oauth2_config.api-public.issuer_url
  })
}
