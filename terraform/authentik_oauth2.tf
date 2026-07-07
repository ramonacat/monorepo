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
