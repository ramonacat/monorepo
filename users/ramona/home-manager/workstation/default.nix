{inputs, ...}: {
  imports = [
    inputs.nixvim.homeModules.nixvim

    ./nixvim

    ./atuin.nix
  ];
}
