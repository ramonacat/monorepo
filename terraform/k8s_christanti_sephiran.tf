resource "ovh_dedicated_server" "sephiran" {
  # ovh_subsidiary = data.ovh_me.account.ovh_subsidiary
  display_name   = "sephiran"
  os             = "debian13_64"
  rescue_ssh_key = hcloud_ssh_key.ramona.public_key
  customizations = {
    ssh_key = hcloud_ssh_key.ramona.public_key
  }
}

resource "dnsimple_zone_record" "A--kubernetes-christanti-sephiran" {
  zone_name = dnsimple_zone.ramona-fun.name
  name      = "sephiran.devices"
  type      = "A"
  value     = ovh_dedicated_server.sephiran.ip
}

resource "tailscale_tailnet_key" "kubernetes-christanti-sephiran" {
  preauthorized       = true
  ephemeral           = true
  recreate_if_invalid = "always"
  tags                = split(" ", data.external.tailscale_tags.result["sephiran"])
}

resource "vault_pki_secret_backend_cert" "kubernetes-christanti-sephiran" {
  backend     = module.pki-hosts.mount_path
  name        = vault_pki_secret_backend_role.hosts.name
  common_name = dnsimple_zone_record.A--kubernetes-christanti-sephiran.qualified_name
  ip_sans = [
    ovh_dedicated_server.sephiran.ip
  ]
  ttl                   = 86400
  min_seconds_remaining = 43200
  auto_renew            = true
}

module "kubernetes-christanti-sephiran-system-build" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.sephiran.config.system.build.toplevel"
}

module "kubernetes-christanti-sephiran-disko" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.sephiran.config.system.build.diskoScript"
}

module "kubernetes-christanti-sephiran-install" {
  source = "github.com/nix-community/nixos-anywhere/terraform/install?ref=1.13.0"

  instance_id       = ovh_dedicated_server.sephiran.service_name
  nixos_system      = module.kubernetes-christanti-sephiran-system-build.result.out
  nixos_partitioner = module.kubernetes-christanti-sephiran-disko.result.out
  target_host       = ovh_dedicated_server.sephiran.ip
  extra_environment = {
    RAMONA_FLAKE_ROOT = abspath("../"),
    HOSTNAME          = "sephiran"
    TAILNET_KEY       = tailscale_tailnet_key.kubernetes-christanti-sephiran.key

    CERTIFICATE     = vault_pki_secret_backend_cert.kubernetes-christanti-sephiran.certificate
    CERTIFICATE_KEY = vault_pki_secret_backend_cert.kubernetes-christanti-sephiran.private_key
  }
  extra_files_script = abspath("scripts/extra-files-script.bash")
}
