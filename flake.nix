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
            ./machines/modules/bcachefs.nix
            ./machines/modules/installed_base.nix
            ./machines/modules/workstation.nix
            ./users/ramona.nix
            ./users/ramona_gui.nix
            home-manager.nixosModules.home-manager
            ./machines/modules/hallewell/hardware.nix
            ./machines/modules/hallewell/virtualisation.nix
            ./machines/modules/hallewell/networking.nix
            ./machines/modules/hallewell/home-assistant.nix
            ./machines/modules/hallewell/users/ramona_gui.nix
            ./machines/hallewell.nix
          ];
        };
        moonfall = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/modules/base.nix
            ./machines/modules/installed_base.nix
            ./machines/modules/workstation.nix
            ./users/ramona.nix
            ./users/ramona_gui.nix
            home-manager.nixosModules.home-manager
            ./machines/modules/moonfall/hardware.nix
            ./machines/modules/moonfall/networking.nix
            ./machines/modules/moonfall/virtualisation.nix
            ./machines/modules/hallewell/users/ramona_gui.nix
            ./machines/moonfall.nix
          ];
        };
        shadowmend = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/modules/base.nix
            ./machines/modules/bcachefs.nix
            ./machines/modules/installed_base.nix
            ./users/ramona.nix
            home-manager.nixosModules.home-manager
            ./machines/modules/shadowmend/hardware.nix
            ./machines/modules/shadowmend/networking.nix
            ./machines/modules/shadowmend/home-assistant.nix
            ./machines/shadowmend.nix
          ];
        };
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./machines/modules/base.nix
            ./machines/modules/bcachefs.nix
            ./machines/modules/iso.nix
          ];
        };
      };
    };
}
