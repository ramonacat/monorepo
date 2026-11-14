module "pki-root" {
  source = "../vault-pki"

  common_name = "kubernetes-${var.cluster-name}"
  name        = "kubernetes-${var.cluster-name}"
  root_path   = var.pki-root-path
}

module "pki-etcd" {
  source = "../vault-pki"

  common_name = "kubernetes-${var.cluster-name}/etcd"
  name        = "kubernetes-${var.cluster-name}-etcd"
  root_path   = module.pki-root.mount_path
}

module "pki-front-proxy" {
  source = "../vault-pki"

  common_name = "kubernetes-${var.cluster-name}/front-proxy"
  name        = "kubernetes-${var.cluster-name}-front-proxy"
  root_path   = module.pki-root.mount_path
}
