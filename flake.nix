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

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    agenix,
    crane,
    disko,
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
      ramona-fun = import ./packages/ramona-fun.nix;
      sawin-gallery = import ./packages/sawin-gallery.nix;
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
      permittedInsecurePackages = [
        "libsoup-2.74.3"
      ];
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
          allHosts =
            builtins.mapAttrs (
              _: value: value.config.system.build.toplevel
            )
            self.nixosConfigurations;
          allHomes = builtins.mapAttrs (_: value: value.activationPackage) self.homeConfigurations;
        in
          pkgs.runCommand "everything" {} (
            "mkdir -p $out/hosts\n"
            + (pkgs.lib.concatStringsSep "\n" (
              pkgs.lib.mapAttrsToList (k: p: "ln -s ${p} $out/hosts/${k}") allHosts
            ))
            + "\nmkdir -p $out/homes\n"
            + (pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: v: "ln -s ${v} $out/homes/${k}") allHomes))
            + "\nln -s ${self.nixosConfigurations.iso.config.system.build.isoImage} $out/iso\n"
            + "\nln -s ${self.nixosConfigurations.iso.config.formats.kexec-bundle} $out/kexec-bundle\n"
          );
        default = coverage;
      }
      // (builtins.mapAttrs (_: v: (v {inherit pkgs craneLib;}).package) packages);
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; let
        package-versions = import ./data/package-versions.nix {inherit pkgs;};
      in [
        alsa-lib.dev
        cargo-leptos
        clang
        google-cloud-sdk
        lua-language-server
        nil
        nil
        nushell
        package-versions.nodejs
        phpactor
        pipewire
        pkg-config
        postgresql_16
        rust-analyzer
        stylua
        terraform
        terraform-ls
        trunk
        udev.dev
        wasm-bindgen-cli

        package-versions.phpPackages.composer
        package-versions.php-dev

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

      extraSpecialArgs = {flake = self;};

      modules = [
        nixvim.homeModules.nixvim

        ./users/ramona/home-manager/base.nix
      ];
    };
    homeConfigurations.ramona-wsl = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {flake = self;};

      modules = [
        nixvim.homeModules.nixvim

        ./users/ramona/home-manager/base.nix
        ./users/ramona/home-manager/wsl.nix
      ];
    };
    nixosConfigurations = let
      common-modules = [
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager
        lix-module.nixosModules.default
        nixvim.nixosModules.nixvim
        {home-manager.sharedModules = [nixvim.homeModules.nixvim];}
      ];
    in {
      hallewell = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          flake = self;
        };
        modules =
          common-modules
          ++ [
            nix-minecraft.nixosModules.minecraft-servers

            ./machines/hallewell.nix
          ];
      };
      shadowsoul = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          flake = self;
        };
        modules =
          common-modules
          ++ [
            ./machines/shadowsoul.nix
          ];
      };
      crimson = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          flake = self;
        };
        modules =
          common-modules
          ++ [
            disko.nixosModules.disko
            ./machines/crimson.nix
          ];
      };
      thornton = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          flake = self;
        };
        modules =
          common-modules
          ++ [
            disko.nixosModules.disko
            ./machines/thornton.nix
          ];
      };
      iso = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          flake = self;
        };
        modules =
          common-modules
          ++ [
            nixos-generators.nixosModules.all-formats

            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

            ./machines/iso.nix
          ];
      };
    };
  };
}
