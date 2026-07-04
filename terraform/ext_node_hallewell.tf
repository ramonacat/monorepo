module "external-node-hallewell" {
  source = "./node-external"

  hostname       = "hallewell"
  vault_pki      = vault_mount.pki-hosts.path
  vault_role     = vault_pki_secret_backend_role.hosts.name
  tailscale_tags = split(" ", data.external.tailscale_tags.result["hallewell"])
}
