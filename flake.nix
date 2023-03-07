{
  description = "Root flake for my machines";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/modules/base.nix
            ./machines/modules/installed_base.nix
            ./machines/modules/workstation.nix
            ./machines/users/ramona.nix
            ./machines/users/ramona_gui.nix
            home-manager.nixosModules.home-manager
            ./machines/desktop.nix
          ];
        };
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./machines/modules/base.nix
            ./machines/modules/iso.nix
          ];
        };
      };
    };
}
