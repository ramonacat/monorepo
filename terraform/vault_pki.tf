resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 315360000 // 10 years(ish)
}

moved {
  from = vault_pki_secret_backend_config_urls.pki
  to   = vault_pki_secret_backend_config_urls.root-a
}

resource "vault_pki_secret_backend_config_urls" "root-a" {
  backend = vault_mount.pki.path
  issuing_certificates = [
    "https://vault.internal.ramona.fun/v1/pki/ca"
  ]
  crl_distribution_points = [
    "https://vault.internal.ramona.fun/v1/pki/crl"
  ]
}

resource "vault_pki_secret_backend_config_auto_tidy" "root-a" {
  backend           = vault_mount.pki.path
  enabled           = true
  tidy_cert_store   = true
  interval_duration = "1h"
}

resource "vault_pki_secret_backend_root_cert" "a" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "ramona root A"
  ttl         = 315360000 // 10 years(ish)
}

resource "local_file" "cert-root-a" {
  filename = "../certificates/ca.crt"
  content  = vault_pki_secret_backend_root_cert.a.certificate
}

resource "vault_mount" "pki-hosts" {
  path                      = "pki-hosts"
  type                      = "pki"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 157680000 // 5 years(ish)
}

moved {
  from = vault_pki_secret_backend_config_urls.pki-hosts
  to   = vault_pki_secret_backend_config_urls.hosts
}

resource "vault_pki_secret_backend_config_urls" "hosts" {
  backend = vault_mount.pki-hosts.path
  issuing_certificates = [
    "https://vault.internal.ramona.fun/v1/pki/ca"
  ]
  crl_distribution_points = [
    "https://vault.internal.ramona.fun/v1/pki/crl"
  ]
}

resource "vault_pki_secret_backend_config_auto_tidy" "hosts" {
  backend           = vault_mount.pki-hosts.path
  enabled           = true
  tidy_cert_store   = true
  interval_duration = "1h"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "hosts" {
  backend     = vault_mount.pki-hosts.path
  common_name = "ramona hosts"
  type        = "internal"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "hosts" {
  backend              = vault_mount.pki.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.hosts.csr
  common_name          = "ramona hosts"
  exclude_cn_from_sans = true
  ttl                  = 157680000 // 5 years(ish)
}

resource "vault_pki_secret_backend_intermediate_set_signed" "hosts" {
  backend     = vault_mount.pki-hosts.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.hosts.certificate
}

resource "local_file" "cert-ca-hosts" {
  filename = "../certificates/ca-hosts.crt"
  content  = vault_pki_secret_backend_intermediate_set_signed.hosts.certificate
}

resource "vault_pki_secret_backend_role" "hosts" {
  backend    = vault_mount.pki-hosts.path
  name       = "hosts"
  issuer_ref = vault_pki_secret_backend_intermediate_set_signed.hosts.imported_issuers[0]
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains  = ["devices.ramona.fun", "localhost"]
  allow_localhost  = false
  allow_subdomains = true
  allow_ip_sans    = true
  client_flag      = true
  server_flag      = true
}

resource "vault_pki_secret_backend_issuer" "hosts" {
  backend     = vault_mount.pki-hosts.path
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.hosts.imported_issuers[0]
  issuer_name = "hosts"
}

resource "vault_mount" "pki-internal" {
  path                      = "pki-internal"
  type                      = "pki"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 157680000 // 5 years(ish)
}

resource "vault_pki_secret_backend_config_auto_tidy" "internal" {
  backend           = vault_mount.pki-internal.path
  enabled           = true
  tidy_cert_store   = true
  interval_duration = "1h"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "internal" {
  backend     = vault_mount.pki-internal.path
  common_name = "ramona internal services"
  type        = "internal"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "internal" {
  backend              = vault_mount.pki.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.internal.csr
  common_name          = "ramona internal services"
  exclude_cn_from_sans = true
  ttl                  = 157680000 // 5 years(ish)
}

resource "vault_pki_secret_backend_intermediate_set_signed" "internal" {
  backend     = vault_mount.pki-internal.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.internal.certificate
}

resource "local_file" "cert-ca-internal" {
  filename = "../certificates/ca-internal.crt"
  content  = vault_pki_secret_backend_intermediate_set_signed.internal.certificate
}

resource "vault_pki_secret_backend_role" "internal" {
  backend    = vault_mount.pki-internal.path
  name       = "internal"
  issuer_ref = vault_pki_secret_backend_intermediate_set_signed.internal.imported_issuers[0]
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains  = ["internal.ramona.fun", "localhost"]
  allow_localhost  = false
  allow_subdomains = true
  allow_ip_sans    = true
  client_flag      = false
  server_flag      = true
}
