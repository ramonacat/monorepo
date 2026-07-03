locals {
  flow_background = "https://f002.backblazeb2.com/file/ramona-uploads/assets/authentik/flow-background.png"
}

resource "authentik_brand" "ramona" {
  domain                           = "."
  default                          = true
  branding_title                   = "ramona account"
  branding_logo                    = "https://f002.backblazeb2.com/file/ramona-uploads/assets/authentik/ramona-account.svg"
  branding_favicon                 = "https://f002.backblazeb2.com/file/ramona-uploads/assets/authentik/favicon.svg"
  branding_default_flow_background = local.flow_background
  branding_custom_css              = <<-EOT
    ak-brand-links, 
    ak-locale-select { 
        display: none; 
    }
  EOT
}

resource "authentik_flow" "default" {
  name               = "login default"
  slug               = "default-authentication-flow"
  title              = "Welcome to your ramona account!"
  designation        = "authentication"
  compatibility_mode = false
  background         = local.flow_background
}

resource "authentik_flow" "default-provider-authorization-implicit-consent" {
  name               = "authorize application"
  slug               = "default-provider-authorization-implicit-consent"
  title              = "Redirecting to %(app)s"
  designation        = "authorization"
  compatibility_mode = false
  background         = local.flow_background
}

resource "authentik_flow" "default-provider-invalidation" {
  name               = "logged out of an application"
  slug               = "default-provider-invalidation-flow"
  title              = "You've logged out of %(app)s."
  designation        = "invalidation"
  compatibility_mode = false
  background         = local.flow_background
}

resource "authentik_group" "global-admins" {
  name         = "global admins"
  is_superuser = true
}
