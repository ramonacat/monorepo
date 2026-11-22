resource "vault_pki_secret_backend_cert" "christanti--argo-cd" {
  backend     = module.pki-christanti.mount_path
  name        = vault_pki_secret_backend_role.christanti-masters.name
  common_name = "system:masters"
  ttl         = 2592000 # 30 days-ish
  auto_renew  = true
}

resource "argocd_cluster" "christanti" {
  # TODO this should be an anycast IP for all the nodes
  server = "https://10.64.0.10:6443"

  config {
    tls_client_config {
      cert_data = vault_pki_secret_backend_cert.christanti--argo-cd.certificate
      key_data  = vault_pki_secret_backend_cert.christanti--argo-cd.private_key
    }
  }
}
