resource "hcloud_server" "redwood" {
    name = "redwood"
    image = "debian-12"
    server_type = "cax31"

    ssh_keys = [
        hcloud_ssh_key.ramona.id
    ]
}

module "system-build" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute         = "..#nixosConfigurations.redwood.config.system.build.toplevel"
}

module "disko" {
  source         = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute      = ".#nixosConfigurations.redwood.config.system.build.diskoScript"
}

module "install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.system-build.result.out
  nixos_partitioner = module.disko.result.out
  target_host       = hcloud_server.redwood.ipv4_address
}
