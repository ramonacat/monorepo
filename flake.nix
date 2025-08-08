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

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
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

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
    nixos-hardware,
    self,
    ...
  }: let
    pkgs = import ./pkgs.nix {inherit inputs local-packages;};
    local-packages = import ./packages {inherit pkgs crane-lib;};
    package-versions = import ./data/package-versions.nix {inherit pkgs;};
    crane-lib = (crane.mkLib pkgs).overrideToolchain package-versions.rust-version;
    source = pkgs.lib.cleanSource ./.;
    source-files = pkgs.lib.filesystem.listFilesRecursive source;
    all-shell-scripts =
      builtins.filter
      (x: (pkgs.lib.hasSuffix ".sh" x || pkgs.lib.hasSuffix ".bash" x) && !(pkgs.lib.strings.hasInfix "/vendor/" x))
      source-files;
    shell-scripts = pkgs.lib.escapeShellArgs all-shell-scripts;
  in {
    formatter.x86_64-linux = pkgs.alejandra;
    checks.x86_64-linux =
      {
        fmt-nix = pkgs.runCommand "fmt-nix" {} ''
          ${pkgs.alejandra}/bin/alejandra --check ${source}

          touch $out
        '';
        fmt-lua = pkgs.runCommand "fmt-lua" {} ''
          ${pkgs.stylua}/bin/stylua --check ${source}

          touch $out
        '';
        fmt-bash = pkgs.runCommand "fmt-bash" {} ''
          ${pkgs.shfmt}/bin/shfmt -d ${shell-scripts}

          touch $out
        '';
        deadnix = pkgs.runCommand "deadnix" {} ''
          ${pkgs.deadnix}/bin/deadnix --fail ${source}

          touch $out
        '';
        statix = pkgs.runCommand "statix" {} ''
          ${pkgs.statix}/bin/statix check ${source}

          touch $out
        '';
        shellcheck = pkgs.runCommand "shellcheck" {} ''
          ${pkgs.shellcheck}/bin/shellcheck --source-path="${pkgs.lib.escapeShellArg "${source}"}" ${shell-scripts}

          touch $out
        '';
      }
      // (pkgs.lib.mergeAttrsList (
        pkgs.lib.mapAttrsToList (_: value: value.checks)
        local-packages.libraries
      ))
      // (pkgs.lib.mergeAttrsList (
        pkgs.lib.mapAttrsToList (_: value: value.checks)
        local-packages.apps
      ));
    packages.x86_64-linux =
      rec {
        coverage = let
          paths = pkgs.lib.mapAttrsToList (_: value: value.coverage) (
            local-packages.libraries // local-packages.apps
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
      // (builtins.mapAttrs (_: v: v.package) local-packages.apps);
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        google-cloud-sdk
        jq
        nil
        nushell
        package-versions.nodejs
        phpactor
        postgresql_16
        rust-analyzer
        shellcheck
        shfmt
        terraform
        terraform-ls

        package-versions.php-packages.composer
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
      RAMONA_FLAKE_ROOT = ./.;
    };
    homeConfigurations.ramona = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {flake = self;};

      modules = [
        nixvim.homeModules.nixvim

        ./users/ramona/home-manager/base
      ];
    };
    homeConfigurations.ramona-wsl = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {flake = self;};

      modules = [
        nixvim.homeModules.nixvim

        ./users/ramona/home-manager/wsl
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
      angelsin-linux = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          flake = self;
        };
        modules =
          common-modules
          ++ [
            nixos-hardware.nixosModules.framework-13-7040-amd

            ./machines/angelsin-linux
          ];
      };
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

            ./machines/hallewell
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
            ./machines/shadowsoul
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
            ./machines/crimson
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
            ./machines/thornton
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

            ./machines/iso
          ];
      };
    };
    hosts-nixos =
      (import ./data/hosts.nix {
        inherit (pkgs) lib;
        flake = self;
      }).nixos;
  };
}
