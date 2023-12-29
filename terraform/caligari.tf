resource "hcloud_server" "caligari" {
    name = "caligari"
    server_type = "cx11"
    location = "nbg1"
    image = "debian-12"

    ssh_keys = [ hcloud_ssh_key.ramona.id ]

    public_net {
        ipv4_enabled = true
        ipv6_enabled = true
    }
}

output "caligari_ip4" {
    value = hcloud_server.caligari.ipv4_address
}

module "caligari-system-build" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute         = ".#nixosConfigurations.caligari.config.system.build.toplevel"
}

module "caligari-disko" {
  source         = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
  attribute      = ".#nixosConfigurations.caligari.config.system.build.diskoScript"
}

module "caligari-install" {
  source            = "github.com/nix-community/nixos-anywhere//terraform/install"
  nixos_system      = module.caligari-system-build.result.out
  nixos_partitioner = module.caligari-disko.result.out
  target_host       = hcloud_server.caligari.ipv4_address
}