resource "hcloud_server" "crimson" {
  name        = "crimson"
  image       = "debian-12"
  server_type = "cpx11"

  ssh_keys = [
    hcloud_ssh_key.ramona.id
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

resource "hcloud_rdns" "crimson-ipv4" {
  ip_address = hcloud_server.crimson.ipv4_address
  dns_ptr    = dnsimple_zone_record.A--crimson-devices-ramona-fun.qualified_name
  server_id  = hcloud_server.crimson.id
}

resource "hcloud_rdns" "crimson-ipv6" {
  ip_address = hcloud_server.crimson.ipv6_address
  dns_ptr    = dnsimple_zone_record.AAAA--crimson-devices-ramona-fun.qualified_name
  server_id  = hcloud_server.crimson.id
}

module "crimson-system-build" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.crimson.config.system.build.toplevel"
}

module "crimson-disko" {
  source = "github.com/nix-community/nixos-anywhere/terraform/nix-build?ref=1.13.0"

  attribute = "..#nixosConfigurations.crimson.config.system.build.diskoScript"
}

module "crimson-install" {
  source = "github.com/nix-community/nixos-anywhere/terraform/install?ref=1.13.0"

  nixos_system      = module.crimson-system-build.result.out
  nixos_partitioner = module.crimson-disko.result.out
  target_host       = hcloud_server.crimson.ipv4_address
}
