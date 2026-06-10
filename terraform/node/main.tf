terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.65.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.29.2"
    }
    dnsimple = {
      source = "dnsimple/dnsimple"
    }
  }
}

resource "tailscale_tailnet_key" "default" {
  expiry              = 86400
  preauthorized       = true
  recreate_if_invalid = "always"
}

resource "hcloud_server" "node" {
  name        = var.name
  image       = var.image
  server_type = "cpx11"
  location    = var.location

  ssh_keys = var.ssh_keys

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

resource "hcloud_rdns" "node-ipv4" {
  ip_address = hcloud_server.node.ipv4_address
  dns_ptr    = dnsimple_zone_record.A--node.qualified_name
  server_id  = hcloud_server.node.id
}

resource "hcloud_rdns" "node-ipv6" {
  ip_address = hcloud_server.node.ipv6_address
  dns_ptr    = dnsimple_zone_record.AAAA--node.qualified_name
  server_id  = hcloud_server.node.id
}

module "system-build" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.${var.name}.config.system.build.toplevel"
}

module "disko" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.${var.name}.config.system.build.diskoScript"
}

module "install" {
  source = "github.com/nix-community/nixos-anywhere/terraform/install?ref=1.13.0"

  nixos_system      = module.system-build.result.out
  nixos_partitioner = module.disko.result.out
  target_host       = hcloud_server.node.ipv4_address
  extra_environment = {
    RAMONA_FLAKE_ROOT = abspath("../"),
    HOSTNAME          = var.name
    TAILNET_KEY       = tailscale_tailnet_key.default.key
  }
  extra_files_script = "../scripts/extra-files-script.bash"
}
