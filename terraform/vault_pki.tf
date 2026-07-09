resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 315360000 // 10 years(ish)
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
  safety_buffer     = "12h"
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

resource "vault_pki_secret_backend_role" "hosts" {
  backend    = module.pki-hosts.mount_path
  name       = "hosts"
  issuer_ref = module.pki-hosts.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains  = ["devices.ramona.fun", "localhost"]
  allow_localhost  = false
  allow_subdomains = true
  allow_ip_sans    = true
  client_flag      = true
  server_flag      = true
}

resource "vault_pki_secret_backend_issuer" "hosts" {
  backend     = module.pki-hosts.mount_path
  issuer_ref  = module.pki-hosts.issuer_ref
  issuer_name = "hosts"
}

module "pki-hosts" {
  source = "./vault-pki"

  name        = "hosts"
  root_path   = vault_mount.pki.path
  common_name = "ramona hosts"
}

module "pki-internal" {
  source = "./vault-pki"

  name        = "internal"
  root_path   = vault_mount.pki.path
  common_name = "ramona internal services"
}

resource "vault_pki_secret_backend_role" "internal" {
  backend    = module.pki-internal.mount_path
  name       = "internal"
  issuer_ref = module.pki-internal.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains  = ["internal.ramona.fun", "localhost", "cluster.local"]
  allow_localhost  = false
  allow_subdomains = true
  allow_ip_sans    = true
  client_flag      = false
  server_flag      = true
}

resource "vault_policy" "cert-self-issue-any-internal" {
  name   = "cert-self-issue-internal"
  policy = <<-EOT
    path "/pki-internal/sign/internal" {
      capabilities = ["create", "patch", "read", "update"]
    }
  EOT
}

# TODO rename -> cert-manager-vault
resource "vault_kubernetes_auth_backend_role" "cert-manager" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cert-manager"
  bound_service_account_names      = ["vault-issuer"]
  bound_service_account_namespaces = ["vault"]
  token_policies                   = ["default", vault_policy.cert-self-issue-any-internal.name]
  audience                         = "vault://vault/vault-self-issuer"
}

module "pki-kubernetes-darkmore" {
  source = "./vault-pki"

  name        = "kubernetes-darkmore"
  root_path   = vault_mount.pki.path
  common_name = "ramona kubernetes - darkmore"
}

resource "vault_pki_secret_backend_issuer" "kubernetes-darkmore-hosts" {
  backend     = module.pki-kubernetes-darkmore.mount_path
  issuer_ref  = module.pki-kubernetes-darkmore.issuer_ref
  issuer_name = "hosts"
}

resource "vault_pki_secret_backend_role" "kubernetes-darkmore-hosts" {
  backend    = module.pki-kubernetes-darkmore.mount_path
  name       = "hosts"
  issuer_ref = module.pki-kubernetes-darkmore.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains  = ["devices.ramona.fun", "localhost"]
  cn_validations   = ["disabled"]
  allow_any_name   = true
  allow_localhost  = false
  allow_subdomains = true
  allow_ip_sans    = true
  client_flag      = true
  server_flag      = true
}

moved {
  from = vault_mount.pki-hosts
  to   = module.pki-hosts.vault_mount.pki
}

moved {
  from = vault_pki_secret_backend_config_auto_tidy.hosts
  to   = module.pki-hosts.vault_pki_secret_backend_config_auto_tidy.cert
}

moved {
  from = vault_pki_secret_backend_intermediate_cert_request.hosts
  to   = module.pki-hosts.vault_pki_secret_backend_intermediate_cert_request.cert
}

moved {
  from = vault_pki_secret_backend_root_sign_intermediate.hosts
  to   = module.pki-hosts.vault_pki_secret_backend_root_sign_intermediate.cert
}

moved {
  from = vault_pki_secret_backend_intermediate_set_signed.hosts
  to   = module.pki-hosts.vault_pki_secret_backend_intermediate_set_signed.cert
}

moved {
  from = local_file.cert-ca-hosts
  to   = module.pki-hosts.local_file.cert
}

moved {
  from = vault_pki_secret_backend_config_urls.hosts
  to   = module.pki-hosts.vault_pki_secret_backend_config_urls.cert
}

moved {
  from = vault_pki_secret_backend_config_urls.pki
  to   = vault_pki_secret_backend_config_urls.root-a
}

moved {
  from = vault_pki_secret_backend_config_urls.pki-hosts
  to   = vault_pki_secret_backend_config_urls.hosts
}

moved {
  from = vault_mount.pki-internal
  to   = module.pki-internal.vault_mount.pki
}

moved {
  from = vault_pki_secret_backend_config_auto_tidy.internal
  to   = module.pki-internal.vault_pki_secret_backend_config_auto_tidy.cert
}

moved {
  from = vault_pki_secret_backend_intermediate_cert_request.internal
  to   = module.pki-internal.vault_pki_secret_backend_intermediate_cert_request.cert
}

moved {
  from = vault_pki_secret_backend_root_sign_intermediate.internal
  to   = module.pki-internal.vault_pki_secret_backend_root_sign_intermediate.cert
}

moved {
  from = vault_pki_secret_backend_intermediate_set_signed.internal
  to   = module.pki-internal.vault_pki_secret_backend_intermediate_set_signed.cert
}

moved {
  from = local_file.cert-ca-internal
  to   = module.pki-internal.local_file.cert
}
