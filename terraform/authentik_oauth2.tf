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
  return {
      # Because authentik only saves the user's full name, and has no concept of first and last names,
      # the full name is used as given name.
      # You can override this behaviour in custom mappings, i.e. `request.user.name.split(" ")`
      "name": request.user.name,
      "given_name": request.user.name,
      "preferred_username": request.user.username,
      "nickname": request.user.username,
      "groups": [group.name for group in request.user.groups.all()],
  }
  EOT
}
