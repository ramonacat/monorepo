{
  description = "Root flake for my machines";

  inputs = {
    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix = {
      url = "git+https://git.lix.systems/lix-project/lix";
      flake = false;
    };

    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alacritty-theme = {
      url = "github:alexghr/alacritty-theme.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
  };

  outputs = {
    NixVirt,
    agenix,
    alacritty-theme,
    crane,
    disko,
    home-manager,
    lanzaboote,
    lix-module,
    nix-minecraft,
    nixos-generators,
    nixos-hardware,
    nixpkgs,
    rust-overlay,
    self,
    ...
  }: let
    packages = {
      music-control = import ./packages/music-control.nix;
      rad = import ./packages/rad.nix;
      ras = import ./packages/ras.nix;
      rat = import ./packages/rat.nix;
      ratweb = import ./packages/ratweb.nix;
    };
    libraries = {
      ratlib = import ./packages/libraries/ratlib.nix;
    };
    overlays = let
      common = [
        (import rust-overlay)
      ];
      mine = architecture: {
        pkgs,
        craneLib,
      }: (_: prev: {
        agenix = agenix.packages."${architecture}-linux".default;
        ramona =
          {
            lan-mouse = (import ./packages/lan-mouse.nix) {inherit pkgs craneLib;};
          }
          // prev.lib.mapAttrs' (name: value: {
            name = "${name}";
            value = (value {inherit pkgs craneLib;}).package;
          })
          packages;
      });
    in {
      x86_64 =
        common
        ++ [
          nix-minecraft.overlay
          alacritty-theme.overlays.default
          (mine "x86_64" {inherit pkgs craneLib;})
        ];
      aarch64 =
        common
        ++ [
          (mine "aarch64" {
            pkgs = pkgsAarch64;
            craneLib = craneLibAarch64;
          })
        ];
    };
    pkgsConfig = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
    pkgs = import nixpkgs {
      overlays = overlays.x86_64;
      system = "x86_64-linux";
      config =
        pkgsConfig
        // {
          # Dark magic for transcoding acceleration on hallewell
          packageOverrides = pkgs: {
            vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
          };
        };
    };
    pkgsAarch64 = import nixpkgs {
      overlays = overlays.aarch64;
      system = "aarch64-linux";
      config = pkgsConfig;
    };
    craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
    rustVersion = pkgs.rust-bin.stable.latest.default.override {
      extensions = ["llvm-tools-preview"];
      targets = ["wasm32-unknown-unknown"];
    };
    rustVersionAarch64 = pkgsAarch64.rust-bin.stable.latest.default.override {extensions = ["llvm-tools-preview"];};
    craneLibAarch64 = (crane.mkLib pkgsAarch64).overrideToolchain rustVersionAarch64;

    shellScripts = builtins.concatStringsSep " " (builtins.filter (x: pkgs.lib.hasSuffix ".sh" x) (pkgs.lib.filesystem.listFilesRecursive (pkgs.lib.cleanSource ./.)));
  in {
    formatter.x86_64-linux = pkgs.alejandra;
    checks.x86_64-linux =
      {
        fmt-nix = pkgs.runCommand "fmt-nix" {} ''
          ${pkgs.alejandra}/bin/alejandra --check ${./.}

          touch $out
        '';
        fmt-lua = pkgs.runCommand "fmt-lua" {} ''
          ${pkgs.stylua}/bin/stylua --check ${./.}

          touch $out
        '';
        deadnix = pkgs.runCommand "deadnix" {} ''
          ${pkgs.deadnix}/bin/deadnix --fail ${./.}

          touch $out
        '';
        statix = pkgs.runCommand "statix" {} ''
          ${pkgs.statix}/bin/statix check ${./.}

          touch $out
        '';
        shellcheck = pkgs.runCommand "shellcheck" {} ''
          ${pkgs.shellcheck}/bin/shellcheck ${shellScripts}

          touch $out
        '';
      }
      // (pkgs.lib.mergeAttrsList (pkgs.lib.mapAttrsToList (_: value: (value {inherit craneLib pkgs;}).checks) libraries))
      // (pkgs.lib.mergeAttrsList (pkgs.lib.mapAttrsToList (_: value: (value {inherit craneLib pkgs;}).checks) packages));
    packages.x86_64-linux = rec {
      coverage = let
        paths = pkgs.lib.mapAttrsToList (_: value: (value {inherit craneLib pkgs;}).coverage) (libraries // packages);
      in
        pkgs.runCommand "coverage" {} ("mkdir $out\n" + (pkgs.lib.concatStringsSep "\n" (builtins.map (p: "ln -s ${p} $out/${p.name}") paths)) + "\n");
      everything = let
        allClosures = builtins.mapAttrs (_: value: value.config.system.build.toplevel) self.nixosConfigurations;
      in
        pkgs.runCommand "everything" {} (
          "mkdir -p $out/hosts\n"
          + (pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: p: "ln -s ${p} $out/hosts/${k}") allClosures))
          + "\nln -s ${self.nixosConfigurations.iso.config.system.build.isoImage} $out/iso\n"
        );
      default = coverage;
    };
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        alsaLib.dev
        cargo-leptos
        clang
        google-cloud-sdk
        lua-language-server
        nil
        pipewire
        pkg-config
        rust-analyzer
        stylua
        terraform
        terraform-ls
        trunk
        wasm-bindgen-cli
        udev.dev
        postgresql_16

        (pkgs.rust-bin.stable.latest.default.override {
          extensions = ["rust-src" "llvm-tools-preview"];
          targets = ["aarch64-unknown-linux-gnu" "wasm32-unknown-unknown"];
        })
      ];
      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    };
    nixosConfigurations = {
      redwood = nixpkgs.lib.nixosSystem {
        pkgs = pkgsAarch64;
        system = "aarch64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          disko.nixosModules.disko

          (import ./modules/base.nix {inherit nixpkgs;})
          ./users/ramona/installed.nix
          ./users/root/base.nix

          ./machines/redwood/hardware.nix
          ./machines/redwood/networking.nix
          ./modules/bcachefs.nix
          ./modules/installed-base.nix
          ./modules/rad.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./modules/zram-swap.nix
        ];
      };
      hallewell = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/hallewell/arrsuite.nix
          ./machines/hallewell/grafana.nix
          ./machines/hallewell/hardware.nix
          ./machines/hallewell/minio.nix
          ./machines/hallewell/nas.nix
          ./machines/hallewell/networking.nix
          ./machines/hallewell/paperless.nix
          ./machines/hallewell/photoprism.nix
          ./machines/hallewell/postgresql.nix
          ./machines/hallewell/ras.nix
          ./machines/hallewell/ratweb.nix
          ./machines/hallewell/syncthing.nix
          ./machines/hallewell/tempo.nix
          ./machines/hallewell/users/ramona.nix
          ./modules/bcachefs.nix
          ./modules/installed-base.nix
          ./modules/rad.nix
          ./modules/ras.nix
          ./modules/syncthing.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./users/ramona/installed.nix
          ./users/root/base.nix
        ];
      };
      moonfall = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          NixVirt.nixosModules.default

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/moonfall/hardware.nix
          ./machines/moonfall/networking.nix
          ./machines/moonfall/users/ramona_gui.nix
          ./machines/moonfall/virtualisation.nix
          ./modules/android-dev.nix
          ./modules/arm-builder.nix
          ./modules/greetd.nix
          ./modules/installed-base.nix
          ./modules/nas-client.nix
          ./modules/rad.nix
          ./modules/steam.nix
          ./modules/syncthing.nix
          ./modules/telegraf.nix
          ./modules/terraform-tokens.nix
          ./modules/updates.nix
          ./modules/workstation.nix
          ./modules/x86-builder.nix
          ./users/ramona/sway.nix
          ./users/root/base.nix
        ];
      };
      shadowsoul = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/shadowsoul/hardware.nix
          ./machines/shadowsoul/networking.nix
          ./machines/shadowsoul/syncthing.nix
          ./machines/shadowsoul/transmission.nix
          ./modules/bcachefs.nix
          ./modules/installed-base.nix
          ./modules/nas-client.nix
          ./modules/rad.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./modules/zram-swap.nix
          ./users/ramona/installed.nix
          ./users/root/base.nix
        ];
      };
      angelsin = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          nixos-hardware.nixosModules.framework-13-7040-amd
          lanzaboote.nixosModules.lanzaboote

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/angelsin/hardware.nix
          ./machines/angelsin/networking.nix
          ./machines/angelsin/users/ramona_gui.nix
          ./machines/angelsin/virtual-screen.nix
          ./modules/android-dev.nix
          ./modules/arm-builder.nix
          ./modules/greetd.nix
          ./modules/installed-base.nix
          ./modules/nas-client.nix
          ./modules/rad.nix
          ./modules/steam.nix
          ./modules/syncthing.nix
          ./modules/telegraf.nix
          ./modules/terraform-tokens.nix
          ./modules/updates.nix
          ./modules/workstation.nix
          ./modules/x86-builder.nix
          ./users/ramona/sway.nix
          ./users/root/installed.nix
        ];
      };
      ananas = nixpkgs.lib.nixosSystem {
        pkgs = pkgsAarch64;
        system = "aarch64-linux";
        modules = [
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager
          lix-module.nixosModules.default
          nixos-generators.nixosModules.all-formats
          nixos-hardware.nixosModules.raspberry-pi-4

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/ananas/hardware.nix
          ./machines/ananas/music-control.nix
          ./machines/ananas/networking.nix
          ./modules/installed-base.nix
          ./modules/nas-client.nix
          ./modules/rad.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./modules/zram-swap.nix
          ./users/ramona/installed.nix
          ./users/root/installed.nix
        ];
      };
      evillian = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          nixos-hardware.nixosModules.microsoft-surface-go
          lanzaboote.nixosModules.lanzaboote

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/evillian/hardware.nix
          ./machines/evillian/networking.nix
          ./modules/greetd.nix
          ./modules/installed-base.nix
          ./modules/nas-client.nix
          ./modules/rad.nix
          ./modules/syncthing.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./modules/workstation.nix
          ./modules/zram-swap.nix
          ./users/ramona/sway.nix
          ./users/root/installed.nix
        ];
      };
      caligari = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          nix-minecraft.nixosModules.minecraft-servers

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/caligari/github-runner.nix
          ./machines/caligari/hardware.nix
          ./machines/caligari/minecraft.nix
          ./machines/caligari/networking.nix
          ./machines/caligari/nginx.nix
          ./machines/caligari/postgresql.nix
          ./machines/caligari/telegraf.nix
          ./modules/bcachefs.nix
          ./modules/installed-base.nix
          ./modules/arm-builder.nix
          ./modules/minecraft.nix
          ./modules/rad.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./users/ramona/installed.nix
          ./users/root/installed.nix
        ];
      };
      iso = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          nixos-generators.nixosModules.all-formats

          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

          (import ./modules/base.nix {inherit nixpkgs;})

          ./modules/bcachefs.nix
          ./modules/iso.nix
          ./users/ramona/base.nix
          ./users/root/base.nix
        ];
      };
    };
  };
}
