{
  description = "Root flake for my machines";

  inputs = {
    agenix.url = "github:ryantm/agenix";
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, home-manager, rust-overlay, crane, nixos-hardware, agenix, nix-vscode-extensions }:
    let
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs { inherit overlays; system = "x86_64-linux"; };
      pkgsAarch64 = import nixpkgs { inherit overlays; system = "aarch64-linux"; };
      pkgsCross = import nixpkgs { inherit overlays; localSystem = "x86_64-linux"; crossSystem = "aarch64-linux"; };
      craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
      rustVersion = pkgs.rust-bin.stable.latest.default;
      rustVersionAarch64 = pkgsAarch64.rust-bin.stable.latest.default;
      craneLibAarch64 = (crane.mkLib pkgsAarch64).overrideToolchain rustVersionAarch64;
      sourceFilter = path: type: craneLib.filterCargoSources path type || (builtins.match ".*/resources/.*" path != null);
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
        buildInputs = with pkgs; [
        ];
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
            targets = [ "aarch64-unknown-linux-gnu" ];
          })
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      };
      nixosConfigurations = {
        hallewell = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/bcachefs.nix
            ./modules/installed_base.nix
            ./modules/telegraf.nix
            (import ./users/ramona.nix { inherit agenix; })
            ./machines/hallewell/hardware.nix
            ./machines/hallewell/networking.nix
            ./machines/hallewell/nas.nix
            ./machines/hallewell/minio.nix
            ./machines/hallewell/tempo.nix
            ./machines/hallewell/grafana.nix
            ./machines/hallewell/postgresql.nix
            ./machines/hallewell/users/ramona.nix
            ./machines/hallewell.nix
          ];
        };
        moonfall = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/installed_base.nix
            ./modules/workstation.nix
            ./modules/telegraf.nix
            (import ./users/ramona.nix { inherit agenix; })
            (import ./users/ramona_gui.nix { inherit barPackage nix-vscode-extensions; })
            ./machines/moonfall/hardware.nix
            ./machines/moonfall/networking.nix
            ./machines/moonfall/virtualisation.nix
            ./machines/moonfall/users/ramona_gui.nix
            ./machines/moonfall.nix
          ];
        };
        shadowmend = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/bcachefs.nix
            ./modules/installed_base.nix
            ./modules/telegraf.nix
            (import ./users/ramona.nix { inherit agenix; })
            ./machines/shadowmend/hardware.nix
            ./machines/shadowmend/networking.nix
            ./machines/shadowmend/rabbitmq.nix
            ./machines/shadowmend/zigbee2mqtt.nix
            (import ./machines/shadowmend/home-automation.nix { inherit homeAutomationPackage; })
            ./machines/shadowmend/users/ramona.nix
            ./machines/shadowmend.nix
          ];
        };
        angelsin = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            nixos-hardware.nixosModules.framework-13-7040-amd

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/installed_base.nix
            ./modules/workstation.nix
            ./modules/telegraf.nix
            (import ./users/ramona.nix { inherit agenix; })
            (import ./users/ramona_gui.nix { inherit barPackage nix-vscode-extensions; })
            ./machines/angelsin/hardware.nix
            ./machines/angelsin/networking.nix
            ./machines/angelsin/users/ramona_gui.nix
            ./machines/angelsin.nix
          ];
        };
        ananas = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            nixos-hardware.nixosModules.raspberry-pi-4

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/installed_base.nix
            ./modules/telegraf.nix
            (import ./users/ramona.nix { inherit agenix; })
            (import ./machines/ananas/hardware.nix {inherit pkgsCross; })
            ./machines/ananas/networking.nix
            (import ./machines/ananas/music-control.nix { inherit ananasMusicControlPackage; })
          ];
        };
        iso = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default

            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/bcachefs.nix
            ./modules/iso.nix
            (import ./users/ramona.nix { inherit agenix; })
          ];
        };
      };
    };
}
