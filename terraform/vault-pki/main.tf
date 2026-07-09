resource "vault_mount" "pki" {
  path                      = "pki-${var.name}"
  type                      = "pki"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 157680000 // 5 years(ish)
}

resource "vault_pki_secret_backend_config_auto_tidy" "cert" {
  backend           = vault_mount.pki.path
  enabled           = true
  tidy_cert_store   = true
  interval_duration = "1h"
  safety_buffer     = "12h"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "cert" {
  backend     = vault_mount.pki.path
  common_name = var.common_name
  type        = "internal"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "cert" {
  backend              = var.root_path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.cert.csr
  common_name          = var.common_name
  exclude_cn_from_sans = true
  ttl                  = 157680000 // 5 years(ish)
}

resource "vault_pki_secret_backend_intermediate_set_signed" "cert" {
  backend     = vault_mount.pki.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.cert.certificate
}

resource "local_file" "cert" {
  filename = "../certificates/ca-${var.name}.crt"
  content  = vault_pki_secret_backend_intermediate_set_signed.cert.certificate
}
