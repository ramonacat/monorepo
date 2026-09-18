resource "authentik_property_mapping_provider_scope" "entitlements" {
  name        = "authentik default OAuth Mapping: Application Entitlements"
  description = "Application entitlements"
  scope_name  = "entitlements"
  expression  = <<-EOT
  entitlements = [entitlement.name for entitlement in request.user.app_entitlements(provider.application)]
  return {
      "entitlements": entitlements,
      "roles": entitlements,
  }
  EOT
}

resource "authentik_property_mapping_provider_scope" "email" {
  name        = "authentik default OAuth Mapping: OpenID 'email'"
  description = "Email address"
  scope_name  = "email"
  expression  = <<-EOT
  return {
      "email": request.user.email,
      "email_verified": False
  }
  EOT
}

resource "authentik_property_mapping_provider_scope" "profile" {
  name        = "authentik default OAuth Mapping: OpenID 'profile'"
  description = "General Profile Information"
  scope_name  = "profile"
  expression  = <<-EOT
  avatar = request.user.avatar
  return delete_none_values({
      "name": request.user.name,
      "given_name": ak_obj_attr(request.user, "given_name", "name"),
      "family_name": ak_obj_attr(request.user, "family_name"),
      "preferred_username": request.user.username,
      "nickname": request.user.username,
      "groups": [group.name for group in request.user.groups.all()],
      # Only expose URL-based avatars: generated avatars are inline base64
      # SVG data URIs, which would bloat the ID/access token for every
      # user without a real avatar URL (OIDC expects a URL here).
      "picture": avatar if avatar and not avatar.startswith("data:") else None,
  })
  EOT
}

resource "authentik_property_mapping_provider_scope" "openid" {
  name       = "authentik default OAuth Mapping: OpenID 'openid'"
  scope_name = "openid"
  expression = <<-EOT
  # This scope is required by the OpenID-spec, and must as such exist in authentik.
  # The scope by itself does not grant any information
  return {}
  EOT
}
