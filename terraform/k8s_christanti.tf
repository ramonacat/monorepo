module "pki-christanti" {
  source = "./kubernetes-pki"

  pki-root-path = vault_mount.pki.path
  cluster-name  = "christanti"
}

resource "vault_pki_secret_backend_role" "christanti-client" {
  backend    = module.pki-christanti.mount_path
  name       = "client"
  issuer_ref = module.pki-christanti.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains = ["devices.ramona.fun", "localhost"]
  cn_validations  = ["disabled"]
  allow_any_name  = true
  client_flag     = true
  server_flag     = false
}

resource "vault_pki_secret_backend_role" "christanti-server" {
  backend    = module.pki-christanti.mount_path
  name       = "server"
  issuer_ref = module.pki-christanti.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains = ["devices.ramona.fun", "localhost"]
  cn_validations  = ["disabled"]
  allow_any_name  = true
  client_flag     = false
  server_flag     = true
}

resource "vault_pki_secret_backend_role" "christanti-clientserver" {
  backend    = module.pki-christanti.mount_path
  name       = "clientserver"
  issuer_ref = module.pki-christanti.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains = ["devices.ramona.fun", "localhost"]
  cn_validations  = ["disabled"]
  allow_any_name  = true
  client_flag     = true
  server_flag     = true
}

resource "vault_pki_secret_backend_role" "christanti-cluster-admins" {
  backend    = module.pki-christanti.mount_path
  name       = "cluster-admins"
  issuer_ref = module.pki-christanti.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains = ["devices.ramona.fun", "localhost"]
  cn_validations  = ["disabled"]
  allow_any_name  = true
  client_flag     = true
  server_flag     = false
  organization    = ["system:cluster-admins"]
}

resource "vault_pki_secret_backend_role" "christanti-cluster-nodes" {
  backend    = module.pki-christanti.mount_path
  name       = "nodes"
  issuer_ref = module.pki-christanti.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains = ["devices.ramona.fun", "localhost"]
  cn_validations  = ["disabled"]
  allow_any_name  = true
  client_flag     = true
  server_flag     = false
  organization    = ["system:nodes"]
}

resource "vault_pki_secret_backend_role" "christanti-masters" {
  backend    = module.pki-christanti.mount_path
  name       = "masters"
  issuer_ref = module.pki-christanti.issuer_ref
  // localhost is disabled and added explicitly so that `vault pki health-check is happy`
  allowed_domains = ["devices.ramona.fun", "localhost"]
  cn_validations  = ["disabled"]
  allow_any_name  = true
  client_flag     = true
  server_flag     = false
  organization    = ["system:masters"]
}

resource "vault_pki_secret_backend_role" "christanti-etcd-clientserver" {
  backend        = module.pki-christanti.etcd_mount_path
  name           = "clientserver"
  issuer_ref     = module.pki-christanti.etcd_issuer_ref
  cn_validations = ["disabled"]
  allow_any_name = true
  client_flag    = true
  server_flag    = true
}

resource "vault_pki_secret_backend_role" "christanti-etcd-client" {
  backend        = module.pki-christanti.etcd_mount_path
  name           = "client"
  issuer_ref     = module.pki-christanti.etcd_issuer_ref
  cn_validations = ["disabled"]
  allow_any_name = true
  client_flag    = true
  server_flag    = false
}

resource "vault_pki_secret_backend_role" "christanti-etcd-server" {
  backend        = module.pki-christanti.etcd_mount_path
  name           = "server"
  issuer_ref     = module.pki-christanti.etcd_issuer_ref
  cn_validations = ["disabled"]
  allow_any_name = true
  client_flag    = false
  server_flag    = true
}

resource "vault_pki_secret_backend_role" "christanti-front-proxy-clientserver" {
  backend        = module.pki-christanti.front_proxy_mount_path
  name           = "clientserver"
  issuer_ref     = module.pki-christanti.front_proxy_issuer_ref
  cn_validations = ["disabled"]
  allow_any_name = true
  client_flag    = true
  server_flag    = true
}

resource "vault_pki_secret_backend_role" "christanti-front-proxy-client" {
  backend        = module.pki-christanti.front_proxy_mount_path
  name           = "client"
  issuer_ref     = module.pki-christanti.front_proxy_issuer_ref
  cn_validations = ["disabled"]
  allow_any_name = true
  client_flag    = true
  server_flag    = false
}

resource "vault_pki_secret_backend_role" "christanti-front-proxy-server" {
  backend        = module.pki-christanti.front_proxy_mount_path
  name           = "server"
  issuer_ref     = module.pki-christanti.front_proxy_issuer_ref
  cn_validations = ["disabled"]
  allow_any_name = true
  client_flag    = false
  server_flag    = true
}
