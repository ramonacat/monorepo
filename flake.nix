{
  description = "Root flake for my machines";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, rust-overlay, crane, nixos-hardware }:
    let
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs { inherit overlays; system = "x86_64-linux"; };
      pkgsAarch64 = import nixpkgs { inherit overlays; system = "aarch64-linux"; };
      craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
      rustVersion = pkgs.rust-bin.stable.latest.default;
      rustVersionAarch64 = pkgsAarch64.rust-bin.stable.latest.default;
      craneLibAarch64 = (crane.mkLib pkgsAarch64).overrideToolchain rustVersionAarch64;
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
      homeAutomationPackageArguments = {
        src = pkgs.lib.cleanSourceWith {
          src = craneLib.path ./apps/home-automation;
          filter = sourceFilter;
        };
      };
      homeAutomationPackageCargoArtifacts = craneLib.buildDepsOnly homeAutomationPackageArguments;
      homeAutomationPackage = craneLib.buildPackage (homeAutomationPackageArguments // {
        cargoArtifacts = homeAutomationPackageCargoArtifacts;
      });
      ananasMusicControlPackageArguments = {
        src = pkgs.lib.cleanSourceWith {
          src = craneLib.path ./apps/ananas-music-control;
          filter = sourceFilter;
        };
      };
      ananasMusicControlPackageCargoArtifacts = craneLibAarch64.buildDepsOnly ananasMusicControlPackageArguments;
      ananasMusicControlPackage = craneLibAarch64.buildPackage (ananasMusicControlPackageArguments // {
        cargoArtifacts = ananasMusicControlPackageCargoArtifacts;
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
            ./machines/modules/hallewell/nas.nix
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
            ./machines/modules/shadowmend/rabbitmq.nix
            ./machines/modules/shadowmend/zigbee2mqtt.nix
            (import ./machines/modules/shadowmend/home-automation.nix { inherit homeAutomationPackage; })
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
        ananas = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-4
            home-manager.nixosModules.home-manager
            ./machines/modules/base.nix
            ./machines/modules/installed_base.nix
            ./users/ramona.nix
            ./machines/modules/ananas/hardware.nix
            ./machines/modules/ananas/networking.nix
            (import ./machines/modules/ananas/music-control.nix { inherit ananasMusicControlPackage; })
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
