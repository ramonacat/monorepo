resource "hcloud_server" "thornton" {
  name        = "thornton"
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

resource "hcloud_volume" "thornton-db" {
  name      = "thornton-db"
  size      = 50
  server_id = hcloud_server.thornton.id
}

resource "hcloud_rdns" "thornton-ipv4" {
  ip_address = hcloud_server.thornton.ipv4_address
  dns_ptr    = trimsuffix(google_dns_record_set.A-thornton-devices-ramona-fun.name, ".")
  server_id  = hcloud_server.thornton.id
}

resource "hcloud_rdns" "thornton-ipv6" {
  ip_address = hcloud_server.thornton.ipv6_address
  dns_ptr    = trimsuffix(google_dns_record_set.AAAA-thornton-devices-ramona-fun.name, ".")
  server_id  = hcloud_server.thornton.id
}

module "thornton-system-build" {
  source    = "github.com/nix-community/nixos-anywhere/terraform/nix-build"
  attribute = "..#nixosConfigurations.thornton.config.system.build.toplevel"
}

module "thornton-disko" {
  source    = "github.com/nix-community/nixos-anywhere/terraform/nix-build"
  attribute = "..#nixosConfigurations.thornton.config.system.build.diskoScript"
}

module "thornton-install" {
  source            = "github.com/nix-community/nixos-anywhere/terraform/install"
  nixos_system      = module.thornton-system-build.result.out
  nixos_partitioner = module.thornton-disko.result.out
  target_host       = hcloud_server.thornton.ipv4_address
  extra_environment = {
    RAMONA_FLAKE_ROOT = abspath("../"),
    HOSTNAME          = "thornton"
  }
  extra_files_script = "scripts/extra-files-script.bash"
}
