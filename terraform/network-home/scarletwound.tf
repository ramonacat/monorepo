
resource "vault_pki_secret_backend_cert" "scarletwound-ssl" {
  backend     = var.vault_pki
  name        = var.vault_role
  common_name = "scarletwound.devices.ramona.fun"
  ip_sans     = ["10.32.0.1", "10.32.2.1"]
  ttl         = 2592000 # 30 days-ish
  auto_renew  = true
}

resource "routeros_system_certificate" "scarletwound-ssl" {
  provider    = routeros.router-scarletwound
  name        = "ssl"
  common_name = vault_pki_secret_backend_cert.scarletwound-ssl.common_name
  import {
    cert_file_content = vault_pki_secret_backend_cert.scarletwound-ssl.certificate
    key_file_content  = vault_pki_secret_backend_cert.scarletwound-ssl.private_key
  }
}

resource "routeros_system_certificate" "scarletwound-ca-root-a" {
  provider    = routeros.router-scarletwound
  name        = "ramona root A"
  common_name = "ramona root A"
  import {
    cert_file_content = var.cert_ca_root
  }
}

resource "routeros_system_certificate" "scarletwound-ca-internal" {
  provider    = routeros.router-scarletwound
  name        = "ramoana internal services"
  common_name = "ramona internal services"
  import {
    cert_file_content = var.cert_ca_internal
  }
}

resource "routeros_system_certificate" "scarletwound-ca-hosts" {
  provider    = routeros.router-scarletwound
  name        = "ramoana hosts"
  common_name = "ramona hosts"
  import {
    cert_file_content = var.cert_ca_hosts
  }
}

resource "routeros_ip_service" "scarletwound-www-ssl" {
  provider    = routeros.router-scarletwound
  disabled    = false
  port        = 443
  numbers     = "www-ssl"
  certificate = routeros_system_certificate.scarletwound-ssl.name
}

resource "routeros_interface_list" "scarletwound-lan" {
  provider = routeros.router-scarletwound
  name     = "LAN"
}

resource "routeros_interface_list" "scarletwound-wan" {
  provider = routeros.router-scarletwound
  name     = "WAN"
}

resource "routeros_system_identity" "scarletwound" {
  provider = routeros.router-scarletwound
  name     = "scarletwound.devices.ramona.fun"
}

resource "routeros_system_clock" "scarletwound" {
  provider       = routeros.router-scarletwound
  time_zone_name = "Europe/Berlin"
}

resource "routeros_ip_dns" "scarletwound" {
  provider = routeros.router-scarletwound

  mdns_repeat_ifaces = [
    routeros_interface_vlan.scarletwound-vlan2.name,
    routeros_interface_vlan.scarletwound-vlan4.name,
    routeros_interface_vlan.scarletwound-vlan5.name,
    routeros_interface_vlan.scarletwound-vlan6.name,
  ]
}
