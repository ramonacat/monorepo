{
  description = "Root flake for my machines";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
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

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs = {
      url = "nixpkgs/nixos-unstable-small";
    };
  };

  outputs = {
    agenix,
    crane,
    home-manager,
    lix-module,
    nix-minecraft,
    nixos-generators,
    nixpkgs,
    nixvim,
    rust-overlay,
    self,
    ...
  }: let
    packages = {
      rad = import ./packages/rad.nix;
      ras2 = import ./packages/ras2.nix;
      ratweb2 = import ./packages/ratweb2.nix;
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
          prev.lib.mapAttrs' (name: value: {
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
          (mine "x86_64" {inherit pkgs craneLib;})
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
          packageOverrides = pkgs: {
            # Dark magic for transcoding acceleration on hallewell
            vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
          };
        };
    };
    craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
    rustVersion = pkgs.rust-bin.stable.latest.default.override {
      extensions = ["llvm-tools-preview"];
      targets = ["wasm32-unknown-unknown"];
    };

    shellScripts = builtins.concatStringsSep " " (
      builtins.filter (x: pkgs.lib.hasSuffix ".sh" x && !(pkgs.lib.strings.hasInfix "/vendor/" x)) (
        pkgs.lib.filesystem.listFilesRecursive (pkgs.lib.cleanSource ./.)
      )
    );
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
      // (pkgs.lib.mergeAttrsList (
        pkgs.lib.mapAttrsToList (_: value: (value {inherit craneLib pkgs;}).checks) libraries
      ))
      // (pkgs.lib.mergeAttrsList (
        pkgs.lib.mapAttrsToList (_: value: (value {inherit craneLib pkgs;}).checks) packages
      ));
    packages.x86_64-linux =
      rec {
        coverage = let
          paths = pkgs.lib.mapAttrsToList (_: value: (value {inherit craneLib pkgs;}).coverage) (
            libraries // packages
          );
        in
          pkgs.runCommand "coverage" {} (
            "mkdir $out\n"
            + (pkgs.lib.concatStringsSep "\n" (builtins.map (p: "ln -s ${p} $out/${p.name}") paths))
            + "\n"
          );
        everything = let
          allClosures =
            builtins.mapAttrs (
              _: value: value.config.system.build.toplevel
            )
            self.nixosConfigurations;
        in
          pkgs.runCommand "everything" {} (
            "mkdir -p $out/hosts\n"
            + (pkgs.lib.concatStringsSep "\n" (
              pkgs.lib.mapAttrsToList (k: p: "ln -s ${p} $out/hosts/${k}") allClosures
            ))
            + "\nln -s ${self.nixosConfigurations.iso.config.system.build.isoImage} $out/iso\n"
            + "\nln -s ${self.nixosConfigurations.iso.config.formats.kexec-bundle} $out/kexec-bundle\n"
          );
        default = coverage;
      }
      // (builtins.mapAttrs (_: v: (v {inherit pkgs craneLib;}).package) packages);
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        alsa-lib.dev
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
        nil
        nodePackages_latest.nodejs
        phpactor

        php84Packages.composer

        (php84.buildEnv {
          extensions = {
            enabled,
            all,
          }:
            enabled ++ [all.xdebug];
          extraConfig = ''
            zend.exception_string_param_max_len=128
          '';
        })
        (rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "llvm-tools-preview"
          ];
          targets = [
            "aarch64-unknown-linux-gnu"
            "wasm32-unknown-unknown"
          ];
        })
      ];
      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    };
    homeConfigurations.ramona = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [
        nixvim.homeModules.nixvim

        ./users/ramona/home-manager.nix
      ];
    };
    homeConfigurations.ramona-wsl = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [
        nixvim.homeModules.nixvim

        ./users/ramona/home-manager.nix
        ./users/ramona/home-manager/wsl.nix
      ];
    };
    nixosConfigurations = {
      hallewell = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          nixvim.nixosModules.nixvim
          {home-manager.sharedModules = [nixvim.homeModules.nixvim];}

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/hallewell/arrsuite.nix
          ./machines/hallewell/atuin-server.nix
          ./machines/hallewell/grafana.nix
          ./machines/hallewell/hardware.nix
          ./machines/hallewell/minio.nix
          ./machines/hallewell/nas.nix
          ./machines/hallewell/navidrome.nix
          ./machines/hallewell/networking.nix
          ./machines/hallewell/nginx.nix
          ./machines/hallewell/paperless.nix
          ./machines/hallewell/photoprism.nix
          ./machines/hallewell/postgresql.nix
          ./machines/hallewell/ras2.nix
          ./machines/hallewell/ratweb2.nix
          ./machines/hallewell/syncthing.nix
          ./machines/hallewell/tempo.nix
          ./machines/hallewell/znc.nix
          ./modules/bcachefs.nix
          ./modules/installed-base.nix
          ./modules/rad.nix
          ./modules/syncthing.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./users/ramona/installed.nix
          ./users/root/base.nix
        ];
      };
      blackwood = nixpkgs.lib.nixosSystem {
        inherit pkgs;

        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          nix-minecraft.nixosModules.minecraft-servers
          nixvim.nixosModules.nixvim
          {home-manager.sharedModules = [nixvim.homeModules.nixvim];}

          (import ./modules/base.nix {inherit nixpkgs;})
          ./machines/blackwood/backup-target.nix
          ./machines/blackwood/github-runner.nix
          ./machines/blackwood/hardware.nix
          ./machines/blackwood/minecraft.nix
          ./machines/blackwood/networking.nix
          ./machines/blackwood/nginx.nix
          ./machines/blackwood/postgresql.nix
          ./machines/blackwood/telegraf.nix
          ./modules/bcachefs.nix
          ./modules/installed-base.nix
          ./modules/minecraft.nix
          ./modules/rad.nix
          ./modules/telegraf.nix
          ./modules/updates.nix
          ./users/ramona/installed.nix
          ./users/root/installed.nix
        ];
      };
      shadowsoul = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          lix-module.nixosModules.default
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          nixvim.nixosModules.nixvim
          {home-manager.sharedModules = [nixvim.homeModules.nixvim];}

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
          ./users/ramona/installed.nix
          ./users/root/base.nix
        ];
      };
      iso = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          nixos-generators.nixosModules.all-formats
          nixvim.nixosModules.nixvim
          {home-manager.sharedModules = [nixvim.homeModules.nixvim];}

          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

          (import ./modules/base.nix {inherit nixpkgs;})

          ./machines/iso/filesystems.nix
          ./modules/bcachefs.nix
          ./users/ramona/base.nix
          ./users/root/base.nix
        ];
      };
    };
  };
}
