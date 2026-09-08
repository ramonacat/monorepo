resource "tls_private_key" "home-assistant-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "home-assistant-oidc" {
  private_key_pem = tls_private_key.home-assistant-oidc.private_key_pem

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  subject {
    common_name = "home-assistant authentik"
  }
}

resource "authentik_certificate_key_pair" "home-assistant-oidc" {
  name             = "home-assistant-oidc"
  certificate_data = tls_self_signed_cert.home-assistant-oidc.cert_pem
  key_data         = tls_private_key.home-assistant-oidc.private_key_pem
}

resource "authentik_provider_oauth2" "home-assistant" {
  name               = "home-assistant"
  client_id          = "home-assistant"
  authorization_flow = authentik_flow.default-provider-authorization-implicit-consent.uuid
  invalidation_flow  = authentik_flow.default-provider-invalidation.uuid
  grant_types        = ["authorization_code"]
  signing_key        = authentik_certificate_key_pair.home-assistant-oidc.id
  property_mappings = [
    authentik_property_mapping_provider_scope.entitlements.id,
    authentik_property_mapping_provider_scope.profile.id,
    authentik_property_mapping_provider_scope.openid.id,
  ]

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "http://homeassistant:8123/auth/oidc/callback"
      redirect_uri_type = "authorization"
    },
    {
      matching_mode     = "strict",
      url               = "https://assistant.home.ramona.fun/auth/oidc/callback"
      redirect_uri_type = "authorization"
    },
  ]
}

data "authentik_provider_oauth2_config" "home-assistant" {
  provider_id = authentik_provider_oauth2.home-assistant.id
}

resource "authentik_application" "home-assistant" {
  name              = "home-assistant"
  slug              = "home-assistant"
  protocol_provider = authentik_provider_oauth2.home-assistant.id
  meta_hide         = true
  meta_launch_url   = "https://assistant.home.ramona.fun/"
}

resource "authentik_policy_binding" "home-assistant-ha-admins" {
  order  = 0
  target = authentik_application.home-assistant.uuid
  group  = authentik_group.ha-admins.id
}

resource "authentik_policy_binding" "home-assistant-ha-users" {
  order  = 1
  target = authentik_application.home-assistant.uuid
  group  = authentik_group.ha-users.id
}

output "home-assistant-client-id" {
  value = authentik_provider_oauth2.home-assistant.client_id
}

output "home-assistant-client-secret" {
  value     = authentik_provider_oauth2.home-assistant.client_secret
  sensitive = true
}

output "home-assistant-client-issuer-url" {
  value = data.authentik_provider_oauth2_config.home-assistant.issuer_url
}

resource "authentik_group" "ha-admins" {
  name = "ha-admins"
}

resource "authentik_group" "ha-users" {
  name = "ha-users"
}
