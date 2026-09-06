resource "vault_pki_secret_backend_cert" "everbleed-ssl" {
  backend     = var.vault_pki
  name        = var.vault_role
  common_name = "everbleed.devices.ramona.fun"
  ip_sans     = ["10.32.2.16"]
  ttl         = 2592000 # 30 days-ish
  auto_renew  = true
}

resource "routeros_system_certificate" "everbleed-ssl" {
  provider    = routeros.router-everbleed
  name        = "ssl"
  common_name = vault_pki_secret_backend_cert.everbleed-ssl.common_name
  import {
    cert_file_content = vault_pki_secret_backend_cert.everbleed-ssl.certificate
    key_file_content  = vault_pki_secret_backend_cert.everbleed-ssl.private_key
  }
}

resource "routeros_system_certificate" "everbleed-ca-root-a" {
  provider    = routeros.router-everbleed
  name        = "ramona root A"
  common_name = "ramona root A"
  import {
    cert_file_content = var.cert_ca_root
  }
}

resource "routeros_system_certificate" "everbleed-ca-internal" {
  provider    = routeros.router-everbleed
  name        = "ramoana internal services"
  common_name = "ramona internal services"
  import {
    cert_file_content = var.cert_ca_internal
  }
}

resource "routeros_system_certificate" "everbleed-ca-hosts" {
  provider    = routeros.router-everbleed
  name        = "ramoana hosts"
  common_name = "ramona hosts"
  import {
    cert_file_content = var.cert_ca_hosts
  }
}

resource "routeros_ip_service" "everbleed-www-ssl" {
  provider    = routeros.router-everbleed
  disabled    = false
  port        = 443
  numbers     = "www-ssl"
  certificate = routeros_system_certificate.everbleed-ssl.name
}

resource "routeros_ip_service" "everbleed-api-ssl" {
  provider    = routeros.router-everbleed
  disabled    = false
  port        = 8729
  numbers     = "api-ssl"
  certificate = routeros_system_certificate.everbleed-ssl.name
}

resource "routeros_system_identity" "everbleed" {
  provider = routeros.router-everbleed
  name     = "everbleed.devices.ramona.fun"
}

resource "routeros_system_clock" "everbleed" {
  provider       = routeros.router-everbleed
  time_zone_name = "Europe/Berlin"
}

resource "routeros_ip_settings" "everbleed" {
  provider   = routeros.router-everbleed
  ip_forward = false
}

resource "routeros_interface_ethernet_switch" "everbleed-switch0" {
  provider          = routeros.router-everbleed
  name              = "switch1"
  qos_hw_offloading = true
}

resource "routeros_ip_address" "everbleed-vlan3" {
  provider  = routeros.router-everbleed
  address   = "10.32.2.16/24"
  interface = routeros_interface_vlan.everbleed-vlan3.name
}

resource "routeros_ip_route" "everbleed-default" {
  provider    = routeros.router-everbleed
  dst_address = "0.0.0.0/0"
  gateway     = "${replace(routeros_ip_address.scarletwound-vlan3.address, "/\\/\\d+$/", "")}%${routeros_interface_vlan.everbleed-vlan3.name}"
}
