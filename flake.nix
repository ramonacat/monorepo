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
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  outputs = { self, nixpkgs, home-manager, rust-overlay, crane, nixos-hardware, agenix, nix-vscode-extensions, nix-minecraft }:
    let
      overlays = [ (import rust-overlay) nix-minecraft.overlay ];
      pkgs = import nixpkgs {
        inherit overlays; system = "x86_64-linux";
        config.allowUnfree = true;
        # Dark magic for transcoding acceleration on hallewell
        config.packageOverrides = pkgs: {
          vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
        };
        config.permittedInsecurePackages = [
          "electron-25.9.0"
        ];
      };
      pkgsAarch64 = import nixpkgs { inherit overlays; system = "aarch64-linux"; };
      pkgsCross = import nixpkgs { inherit overlays; localSystem = "x86_64-linux"; crossSystem = "aarch64-linux"; };
      craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
      rustVersion = pkgs.rust-bin.stable.latest.default;
      rustVersionAarch64 = pkgsAarch64.rust-bin.stable.latest.default;
      craneLibAarch64 = (crane.mkLib pkgsAarch64).overrideToolchain rustVersionAarch64;
      barPackage = import ./packages/bar.nix { inherit pkgs; inherit craneLib; };
      homeAutomationPackage = import ./packages/home-automation.nix { inherit pkgs; inherit craneLib; };
      ananasMusicControlPackage = import ./packages/music-control.nix { pkgs = pkgsAarch64; craneLib = craneLibAarch64; };
    in
    {
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;
      checks.x86_64-linux = {
        fmt-nix = pkgs.runCommand "fmt-nix" { } ''
          ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}

          touch $out
        '';
        fmt-lua = pkgs.runCommand "fmt-lua" { } ''
          ${pkgs.stylua}/bin/stylua --check ${./.}

          touch $out
        '';
      };
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          pkg-config
          pipewire
          clang
          alsaLib.dev
          rust-analyzer
          lua-language-server
          terraform
          google-cloud-sdk
          stylua
          (pkgs.rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" ];
            targets = [ "aarch64-unknown-linux-gnu" ];
          })
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      };
      nixosConfigurations = {
        hallewell = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/bcachefs.nix
            ./modules/installed_base.nix
            ./modules/telegraf.nix
            ./modules/syncthing.nix
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
          inherit pkgs;
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/installed_base.nix
            ./modules/workstation.nix
            ./modules/nas-client.nix
            ./modules/telegraf.nix
            ./modules/terraform-tokens.nix
            ./modules/syncthing.nix
            (import ./users/ramona.nix { inherit agenix; })
            (import ./users/ramona/gui.nix { inherit nix-vscode-extensions; })
            (import ./users/ramona/sway.nix { inherit barPackage; })
            ./machines/moonfall/hardware.nix
            ./machines/moonfall/networking.nix
            ./machines/moonfall/virtualisation.nix
            ./machines/moonfall/users/ramona_gui.nix
            ./machines/moonfall.nix
          ];
        };
        shadowmend = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/bcachefs.nix
            ./modules/installed_base.nix
            ./modules/nas-client.nix
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
          inherit pkgs;
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            nixos-hardware.nixosModules.framework-13-7040-amd

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/installed_base.nix
            ./modules/workstation.nix
            ./modules/nas-client.nix
            ./modules/telegraf.nix
            ./modules/terraform-tokens.nix
            ./modules/syncthing.nix
            (import ./users/ramona.nix { inherit agenix; })
            (import ./users/ramona/gui.nix { inherit nix-vscode-extensions; })
            (import ./users/ramona/sway.nix { inherit barPackage; })
            ./machines/angelsin/hardware.nix
            ./machines/angelsin/networking.nix
            ./machines/angelsin/users/ramona_gui.nix
            ./machines/angelsin.nix
          ];
        };
        ananas = nixpkgs.lib.nixosSystem {
          pkgs = pkgsAarch64;
          system = "aarch64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            nixos-hardware.nixosModules.raspberry-pi-4

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/installed_base.nix
            ./modules/telegraf.nix
            ./modules/nas-client.nix
            (import ./users/ramona.nix { inherit agenix; })
            (import ./machines/ananas/hardware.nix { inherit pkgsCross; })
            ./machines/ananas/networking.nix
            (import ./machines/ananas/music-control.nix { inherit ananasMusicControlPackage; })
            ./machines/ananas.nix
          ];
        };
        evillian = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            nixos-hardware.nixosModules.microsoft-surface-go

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/installed_base.nix
            ./modules/workstation.nix
            ./modules/nas-client.nix
            ./modules/telegraf.nix
            ./modules/syncthing.nix
            (import ./users/ramona.nix { inherit agenix; })
            (import ./users/ramona/gui.nix { inherit nix-vscode-extensions; })
            ./machines/evillian/hardware.nix
            ./machines/evillian/networking.nix
            ./machines/evillian.nix
          ];
        };
        caligari = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            nix-minecraft.nixosModules.minecraft-servers

            (import ./modules/base.nix { inherit nixpkgs; })
            ./modules/bcachefs.nix
            ./modules/installed_base.nix
            ./modules/telegraf.nix
            ./modules/minecraft.nix
            (import ./users/ramona.nix { inherit agenix; })
            ./machines/caligari/hardware.nix
            ./machines/caligari/networking.nix
            ./machines/caligari/minecraft.nix
            ./machines/caligari/github-runner.nix
            ./machines/caligari.nix
          ];
        };
        iso = nixpkgs.lib.nixosSystem {
          inherit pkgs;
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
