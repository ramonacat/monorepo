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
