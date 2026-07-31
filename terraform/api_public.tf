resource "tls_private_key" "api-public-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "api-public-oidc" {
  private_key_pem = tls_private_key.api-public-oidc.private_key_pem

  subject {
    common_name = "api-public authentik"
  }

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
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

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://red-proxy.ramona.fun/authorize"
      redirect_uri_type = "authorization"
    },
  ]
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
