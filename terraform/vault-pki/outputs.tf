output "mount_path" {
  value = vault_mount.pki.path
}

output "issuer_ref" {
  value = vault_pki_secret_backend_intermediate_set_signed.cert.imported_issuers[0]
}

output "certificate" {
  value = vault_pki_secret_backend_intermediate_set_signed.cert.certificate
}
