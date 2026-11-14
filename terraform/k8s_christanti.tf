module "pki-christanti" {
  source        = "./kubernetes-pki"
  pki-root-path = vault_mount.pki.path
  cluster-name  = "christanti"
}
