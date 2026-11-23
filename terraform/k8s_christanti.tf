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

resource "vault_mount" "kv-kubernetes-christanti" {
  path    = "secrets/kubernetes/christanti"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_backend_v2" "kubernetes-christanti" {
  mount        = vault_mount.kv-kubernetes-christanti.path
  max_versions = 5
}

resource "vault_auth_backend" "kubernetes-christanti" {
  path = "kubernetes-christanti"
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "christanti" {
  backend         = vault_auth_backend.kubernetes-christanti.path
  kubernetes_host = "https://control-plane.christanti.ramona.fun"
}

resource "vault_policy" "kv-kubernetes-christanti" {
  name   = "kv-kubernetes-christanti"
  policy = <<-EOT
    path "/${vault_mount.kv-kubernetes-christanti.path}/cluster/*" {
      capabilities = ["deny"]
    }

    path "/${vault_mount.kv-kubernetes-christanti.path}/*" {
      capabilities = ["create", "update", "patch", "delete", "read", "list"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "christanti-kv" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "kv-kubernetes-christanti"
  bound_service_account_names      = ["vault-client"]
  bound_service_account_namespaces = ["external-secrets"]
  token_policies                   = ["default", vault_policy.kv-kubernetes-christanti.name]
}

resource "vault_policy" "christanti-sa-key" {
  name = "christanti-sa-key"

  policy = <<-EOT
    path "/secrets/kubernetes/christanti/data/cluster/service-account-key" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_cert_auth_backend_role" "hosts-kubernetes-christanti" {
  name         = "hosts-kubernetes-christanti"
  certificate  = module.pki-hosts.certificate
  backend      = vault_auth_backend.cert.path
  ocsp_enabled = false
  token_policies = setunion(
    vault_cert_auth_backend_role.hosts.token_policies,
    [
      vault_policy.cert-issue-kubernetes-christanti.name,
      vault_policy.cert-issue-kubernetes-christanti-etcd.name,
      vault_policy.cert-issue-kubernetes-christanti-front-proxy.name,
      vault_policy.christanti-sa-key.name,
    ]
  )
}

resource "vault_kubernetes_auth_backend_role" "cert-manager-christanti" {
  backend                          = vault_auth_backend.kubernetes-christanti.path
  role_name                        = "cert-manager-christanti"
  bound_service_account_names      = ["vault-issuer"]
  bound_service_account_namespaces = ["vault", "cert-manager"]
  token_policies                   = ["default", vault_policy.cert-self-issue-any-internal.name]
  audience                         = "vault://vault-self-issuer"
}
