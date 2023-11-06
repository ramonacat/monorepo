{
  description = "Root flake for my machines";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, rust-overlay, crane }:
    let
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs { inherit overlays; system = "x86_64-linux"; };
      craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
      rustVersion = pkgs.rust-bin.stable.latest.default;
      sourceFilter = path: type: craneLib.filterCargoSources path type;
      packageArguments = {
        src = pkgs.lib.cleanSourceWith {
          src = craneLib.path ./apps/bar;
          filter = sourceFilter;
        };
        buildInputs = with pkgs; [
          pkg-config
          pipewire
          clang
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      };
      cargoArtifacts = craneLib.buildDepsOnly packageArguments;
      barPackage = craneLib.buildPackage (packageArguments // {
        inherit cargoArtifacts;
      });
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        shellHook = ''
        '';
        packages = with nixpkgs.legacyPackages.x86_64-linux; [
          pkg-config
          pipewire
          clang
          (pkgs.rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" ];
          })
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      };
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/modules/base.nix
            ./machines/modules/bcachefs.nix
            ./machines/modules/installed_base.nix
            ./users/ramona.nix
            home-manager.nixosModules.home-manager
            ./machines/modules/hallewell/hardware.nix
            ./machines/modules/hallewell/networking.nix
            ./machines/modules/hallewell/users/ramona.nix
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
            (import ./users/ramona_gui.nix { inherit barPackage; })
            home-manager.nixosModules.home-manager
            ./machines/modules/moonfall/hardware.nix
            ./machines/modules/moonfall/networking.nix
            ./machines/modules/moonfall/virtualisation.nix
            ./machines/modules/moonfall/users/ramona_gui.nix
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
            ./machines/modules/shadowmend/users/ramona.nix
            ./machines/shadowmend.nix
          ];
        };
        angelsin = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/modules/base.nix
            ./machines/modules/installed_base.nix
            ./machines/modules/workstation.nix
            ./users/ramona.nix
            (import ./users/ramona_gui.nix { inherit barPackage; })
            home-manager.nixosModules.home-manager
            ./machines/modules/angelsin/hardware.nix
            ./machines/modules/angelsin/networking.nix
            ./machines/modules/angelsin/users/ramona_gui.nix
            ./machines/angelsin.nix
          ];
        };
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./machines/modules/base.nix
            ./machines/modules/bcachefs.nix
            ./machines/modules/iso.nix
            ./users/ramona.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
