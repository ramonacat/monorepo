resource "contabo_instance" "kubernetes-christanti-norwood" {
  display_name         = "norwood"
  product_id           = "V154"
  region               = "EU"
  existing_instance_id = 100214087
  image_id             = "f5193fe6-d547-4726-9271-cdb2819833fd"

  ssh_keys = [contabo_secret.ramona.id]
}

resource "dnsimple_zone_record" "A--kubernetes-christanti-norwood" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "norwood.devices"
  type      = "A"
  value     = contabo_instance.kubernetes-christanti-norwood.ip_config[0].v4[0].ip
}

resource "tailscale_tailnet_key" "kubernetes-christanti-norwood" {
  preauthorized       = true
  ephemeral           = true
  recreate_if_invalid = "always"
  tags                = split(" ", data.external.tailscale_tags.result["norwood"])
}

resource "vault_pki_secret_backend_cert" "kubernetes-christanti-norwood" {
  backend     = module.pki-hosts.mount_path
  name        = vault_pki_secret_backend_role.hosts.name
  common_name = dnsimple_zone_record.A--kubernetes-christanti-norwood.qualified_name
  ip_sans = [
    contabo_instance.kubernetes-christanti-norwood.ip_config[0].v4[0].ip,
    contabo_instance.kubernetes-christanti-norwood.ip_config[0].v6[0].ip
  ]
  ttl                   = 86400
  min_seconds_remaining = 43200
  auto_renew            = true
}

module "kubernetes-christanti-norwood-system-build" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.norwood.config.system.build.toplevel"
}

module "kubernetes-christanti-norwood-disko" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.norwood.config.system.build.diskoScript"
}

module "kubernetes-christanti-norwood-install" {
  source = "github.com/nix-community/nixos-anywhere/terraform/install?ref=1.13.0"

  instance_id       = contabo_instance.kubernetes-christanti-norwood.id
  nixos_system      = module.kubernetes-christanti-norwood-system-build.result.out
  nixos_partitioner = module.kubernetes-christanti-norwood-disko.result.out
  target_host       = contabo_instance.kubernetes-christanti-norwood.ip_config[0].v4[0].ip
  extra_environment = {
    RAMONA_FLAKE_ROOT = abspath("../"),
    HOSTNAME          = "norwood"
    TAILNET_KEY       = tailscale_tailnet_key.kubernetes-christanti-norwood.key

    CERTIFICATE     = vault_pki_secret_backend_cert.kubernetes-christanti-norwood.certificate
    CERTIFICATE_KEY = vault_pki_secret_backend_cert.kubernetes-christanti-norwood.private_key
  }
  extra_files_script = abspath("scripts/extra-files-script.bash")
}
