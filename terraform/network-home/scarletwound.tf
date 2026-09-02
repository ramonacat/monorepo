resource "routeros_interface_bridge" "scarletwound-bridge0" {
  provider = routeros.router-scarletwound

  name = "bridge0"
}

resource "routeros_interface_vlan" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan2"
  comment   = "workstations"
}

resource "routeros_interface_vlan" "scarletwound-vlan7" {
  provider = routeros.router-scarletwound

  interface = routeros_interface_bridge.scarletwound-bridge0.name
  name      = "vlan7"
  comment   = "ISP"
}

resource "routeros_ip_pool" "scarletwound-workstations" {
  provider = routeros.router-scarletwound
  name     = "pool-workstations"
  ranges   = ["10.32.1.32-10.32.1.254"]
  comment  = "workstations/vlan2"
}

resource "routeros_dhcp_server" "scarletwound-workstations" {
  provider                  = routeros.router-scarletwound
  interface                 = routeros_interface_vlan.scarletwound-vlan2.name
  name                      = "dhcp-workstations"
  lease_time                = "6h"
  dynamic_lease_identifiers = "client-mac,client-id"
}

resource "routeros_interface_bridge_port" "scarletwound-ether1" {
  provider    = routeros.router-scarletwound
  interface   = "ether1"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 2
}

resource "routeros_interface_bridge_port" "scarletwound-ether2" {
  provider    = routeros.router-scarletwound
  interface   = "ether2"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 2
}

resource "routeros_interface_bridge_port" "scarletwound-ether3" {
  provider    = routeros.router-scarletwound
  interface   = "ether3"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-only-untagged-and-priority-tagged"
  pvid        = 2
}

resource "routeros_interface_bridge_port" "scarletwound-ether5" {
  provider    = routeros.router-scarletwound
  interface   = "ether5"
  bridge      = routeros_interface_bridge.scarletwound-bridge0.name
  frame_types = "admit-all"
  pvid        = 2
}

resource "routeros_bridge_vlan" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged   = [routeros_interface_bridge.scarletwound-bridge0.name, "ether5"]
  untagged = ["ether1", "ether2", "ether3"]
  vlan_ids = [2]
}

resource "routeros_bridge_vlan" "scarletwound-vlan7" {
  provider = routeros.router-scarletwound
  bridge   = routeros_interface_bridge.scarletwound-bridge0.name
  tagged   = [routeros_interface_bridge.scarletwound-bridge0.name, "ether5"]
  vlan_ids = [7]
}

resource "routeros_ip_address" "scarletwound-bridge0" {
  provider  = routeros.router-scarletwound
  address   = "10.32.0.1/24"
  interface = routeros_interface_bridge.scarletwound-bridge0.name
  network   = "10.32.0.0"
}

resource "routeros_ip_address" "scarletwound-vlan2" {
  provider  = routeros.router-scarletwound
  address   = "10.32.1.1/24"
  interface = routeros_interface_vlan.scarletwound-vlan2.name
  network   = "10.32.1.0"
}

resource "routeros_ip_dhcp_client" "scarletwound-vlan7" {
  provider  = routeros.router-scarletwound
  interface = routeros_interface_vlan.scarletwound-vlan7.name
}

resource "routeros_ip_dhcp_server_network" "scarletwound-vlan2" {
  provider = routeros.router-scarletwound
  address  = "10.32.1.0/24"
  gateway  = "10.32.1.1"
  netmask  = 24
}

resource "routeros_ip_firewall_filter" "scarletwound-forward-accept" {
  provider = routeros.router-scarletwound
  chain    = "forward"
  action   = "accept"
}

resource "routeros_ip_firewall_filter" "scarletwound-input-accept" {
  provider = routeros.router-scarletwound
  chain    = "input"
  action   = "accept"
}

resource "routeros_ip_firewall_nat" "scarletwound-masquerade-vlan2-vlan7" {
  provider      = routeros.router-scarletwound
  action        = "masquerade"
  chain         = "srcnat"
  in_interface  = routeros_interface_vlan.scarletwound-vlan2.name
  out_interface = routeros_interface_vlan.scarletwound-vlan7.name
}

resource "vault_pki_secret_backend_cert" "scarletwound-ssl" {
  backend     = var.vault_pki
  name        = var.vault_role
  common_name = "scarletwound.devices.ramona.fun"
  ip_sans     = ["10.32.0.1"]
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
