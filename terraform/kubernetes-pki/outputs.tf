output "mount_path" {
  value = module.pki-root.mount_path
}

output "issuer_ref" {
  value = module.pki-root.issuer_ref
}

output "etcd_mount_path" {
  value = module.pki-etcd.mount_path
}

output "etcd_issuer_ref" {
  value = module.pki-etcd.issuer_ref
}

output "front_proxy_mount_path" {
  value = module.pki-front-proxy.mount_path
}

output "front_proxy_issuer_ref" {
  value = module.pki-front-proxy.issuer_ref
}
