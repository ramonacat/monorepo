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
    crane,
    self,
    ...
  }: let
    system = "x86_64-linux";
    local-packages."${system}" = import ./packages {
      crane-lib = crane-lib."${system}";
      pkgs = pkgs."${system}";
    };
    pkgs."${system}" = import ./pkgs.nix {
      inherit inputs;
      local-packages = local-packages."${system}";
      system = "x86_64-linux";
    };
    package-versions."${system}" = import ./data/package-versions.nix {pkgs = pkgs."${system}";};
    crane-lib."${system}" = (crane.mkLib pkgs."${system}").overrideToolchain package-versions."${system}".rust-version;
    output-arguments = {
      inherit inputs;

      pkgs = pkgs."${system}";
      local-packages = local-packages."${system}";
      package-versions = package-versions."${system}";
      flake = self;
    };
  in {
    formatter."${system}" = pkgs."${system}".alejandra;
    checks."${system}" = import ./outputs/checks.nix output-arguments;
    packages."${system}" = import ./outputs/packages.nix output-arguments;
    devShells."${system}".default = import ./outputs/dev-shells.nix output-arguments;
    homeConfigurations = import ./outputs/home-configurations-x86_64-linux.nix {
      inherit inputs;

      pkgs = pkgs.x86_64-linux;
      flake = self;
    };
    nixosConfigurations = import ./outputs/nixos-configurations-x86_64-linux.nix {
      inherit inputs;

      pkgs = pkgs.x86_64-linux;
      flake = self;
    };
    hosts-nixos =
      (import ./data/hosts.nix {
        inherit (pkgs."${system}") lib;
        flake = self;
      }).nixos;
  };
}
