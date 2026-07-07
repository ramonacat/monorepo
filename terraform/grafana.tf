resource "tls_private_key" "grafana-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "grafana-oidc" {
  private_key_pem = tls_private_key.grafana-oidc.private_key_pem

  subject {
    common_name = "grafana authentik"
  }

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "authentik_certificate_key_pair" "grafana-oidc" {
  name             = "grafana-oidc"
  certificate_data = tls_self_signed_cert.grafana-oidc.cert_pem
  key_data         = tls_private_key.grafana-oidc.private_key_pem
}

resource "authentik_provider_oauth2" "grafana" {
  name               = "grafana"
  client_id          = "grafana"
  authorization_flow = authentik_flow.default-provider-authorization-implicit-consent.uuid
  invalidation_flow  = authentik_flow.default-provider-invalidation.uuid
  grant_types        = ["authorization_code"]
  signing_key        = authentik_certificate_key_pair.grafana-oidc.id
  property_mappings = [
    authentik_property_mapping_provider_scope.entitlements.id,
    authentik_property_mapping_provider_scope.email.id,
  ]
  logout_method = "frontchannel"
  logout_uri    = "https://grafana.infrastructure.ramona.fun/logout"

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://grafana.infrastructure.ramona.fun/login/generic_oauth"
      redirect_uri_type = "authorization"
    },
  ]
}

data "authentik_provider_oauth2_config" "grafana" {
  provider_id = authentik_provider_oauth2.grafana.id
}

resource "authentik_application" "grafana" {
  name              = "grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
}

resource "authentik_application_entitlement" "grafana_admins" {
  name        = "Grafana Admins"
  application = authentik_application.grafana.uuid
}

resource "authentik_policy_binding" "grafana_admins" {
  target = authentik_application_entitlement.grafana_admins.id
  group  = authentik_group.global-admins.id
  order  = 0
}

resource "authentik_application_entitlement" "grafana_editors" {
  name        = "Grafana Editors"
  application = authentik_application.grafana.uuid
}

resource "authentik_policy_binding" "grafana_editors" {
  target = authentik_application_entitlement.grafana_editors.id
  group  = authentik_group.global-admins.id
  order  = 0
}

resource "grafana_sso_settings" "authentik" {
  provider_name = "generic_oauth"

  oauth2_settings {
    allow_sign_up        = true
    api_url              = data.authentik_provider_oauth2_config.grafana.user_info_url
    auth_url             = data.authentik_provider_oauth2_config.grafana.authorize_url
    auto_login           = true
    client_secret        = authentik_provider_oauth2.grafana.client_secret
    client_id            = authentik_provider_oauth2.grafana.client_id
    scopes               = "openid profile email entitlements"
    token_url            = data.authentik_provider_oauth2_config.grafana.token_url
    signout_redirect_url = data.authentik_provider_oauth2_config.grafana.logout_url
    role_attribute_path  = "contains(entitlements[*], 'Grafana Admins') && 'Admin' || contains(entitlements[*], 'Grafana Editors') && 'Editor' || 'Viewer'"
  }
}
