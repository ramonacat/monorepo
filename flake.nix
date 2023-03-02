{
  description = "Root flake for my machines";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11-small";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:msteen/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, home-manager, vscode-server }: {
    nixosConfigurations = {
      dev-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vscode-server.nixosModule
          home-manager.nixosModules.home-manager
          ./machines/dev-vm.nix
        ];
      };
    };
  };
}
