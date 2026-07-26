module "node-tmp-migrator" {
  source = "./node"

  name           = "tmp-migrator"
  vault_pki      = module.pki-hosts.mount_path
  vault_role     = vault_pki_secret_backend_role.hosts.name
  firewall_ids   = [hcloud_firewall.fw.id]
  tailscale_tags = split(" ", data.external.tailscale_tags.result["tmp-migrator"])
  dns_zone_name  = dnsimple_zone.ramona-fun.name
  ssh_keys       = [hcloud_ssh_key.ramona.id, hcloud_ssh_key.ci.id]
}
