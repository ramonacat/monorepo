module "external-node-shadowsoul" {
  source = "./node-external"

  hostname       = "shadowsoul"
  vault_pki      = vault_mount.pki-hosts.path
  vault_role     = vault_pki_secret_backend_role.hosts.name
  tailscale_tags = split(" ", data.external.tailscale_tags.result["shadowsoul"])
}
