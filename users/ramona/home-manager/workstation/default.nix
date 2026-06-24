{ inputs, pkgs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim

    ./nixvim

    ./atuin.nix
    ./npm.nix
  ];
  config = {
    home.packages = with pkgs; [ ramona.fup ];
  };
}
