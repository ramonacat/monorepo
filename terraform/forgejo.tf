resource "tls_private_key" "forgejo-oidc" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "forgejo-oidc" {
  private_key_pem = tls_private_key.forgejo-oidc.private_key_pem

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  subject {
    common_name = "forgejo authentik"
  }
}

resource "authentik_certificate_key_pair" "forgejo-oidc" {
  name             = "forgejo-oidc"
  certificate_data = tls_self_signed_cert.forgejo-oidc.cert_pem
  key_data         = tls_private_key.forgejo-oidc.private_key_pem
}

resource "authentik_property_mapping_provider_scope" "forgejo" {
  name       = "forgejo"
  scope_name = "forgejo"
  expression = <<-EOT
    entitlement_names = {
        entitlement.name
        for entitlement in request.user.app_entitlements(provider.application)
    }
    forgejo_claims = {}

    if "gituser" in entitlement_names:
        forgejo_claims["forgejo"] = "user"
    if "gitadmin" in entitlement_names:
        forgejo_claims["forgejo"] = "admin"
    if "gitrestricted" in entitlement_names:
        forgejo_claims["forgejo"] = "restricted"

    return forgejo_claims
  EOT
}


resource "authentik_provider_oauth2" "forgejo" {
  name               = "forgejo"
  client_id          = "forgejo"
  authorization_flow = authentik_flow.default-provider-authorization-implicit-consent.uuid
  invalidation_flow  = authentik_flow.default-provider-invalidation.uuid
  grant_types        = ["authorization_code"]
  signing_key        = authentik_certificate_key_pair.forgejo-oidc.id
  property_mappings = [
    authentik_property_mapping_provider_scope.forgejo.id,
    authentik_property_mapping_provider_scope.email.id,
    authentik_property_mapping_provider_scope.profile.id,
  ]

  allowed_redirect_uris = [
    {
      matching_mode     = "strict",
      url               = "https://code.ramona.fun/user/oauth2/authentik/callback"
      redirect_uri_type = "authorization"
    },
  ]
}

resource "authentik_application" "forgejo" {
  name              = "forgejo"
  slug              = "forgejo"
  protocol_provider = authentik_provider_oauth2.forgejo.id
}

resource "authentik_application_entitlement" "forgejo--user" {
  name        = "user"
  application = authentik_application.forgejo.uuid
}

resource "authentik_policy_binding" "infra-users--forgejo--user" {
  order  = 0
  target = authentik_application_entitlement.forgejo--user.id
  group  = authentik_group.infra-users.id
}

resource "authentik_application_entitlement" "forgejo--admin" {
  name        = "admin"
  application = authentik_application.forgejo.uuid
}

resource "authentik_policy_binding" "infra-users--forgejo--admin" {
  order  = 0
  target = authentik_application_entitlement.forgejo--admin.id
  group  = authentik_group.infra-users.id
}

resource "authentik_application_entitlement" "forgejo--restricted" {
  name        = "restricted"
  application = authentik_application.forgejo.uuid
}

resource "authentik_policy_binding" "global-admins--forgejo" {
  order  = 0
  target = authentik_application.forgejo.uuid
  group  = authentik_group.global-admins.id
}

resource "authentik_policy_binding" "infra-users--forgejo" {
  order  = 0
  target = authentik_application.forgejo.uuid
  group  = authentik_group.infra-users.id
}

resource "vault_kv_secret_v2" "forgejo--oauth" {
  mount = "secrets/kubernetes/darkmore"
  name  = "forgejo/oauth"
  data_json = jsonencode({
    CLIENT_ID     = authentik_provider_oauth2.forgejo.client_id
    CLIENT_SECRET = authentik_provider_oauth2.forgejo.client_secret
  })
}

