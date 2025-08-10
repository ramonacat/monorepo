{
  modulesPath,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.home-manager.nixosModules.home-manager
    inputs.lix-module.nixosModules.default

    ../../modules/roles.nix

    ./base.nix
    ./bcachefs.nix
    ./kernel.nix
    ./locale.nix
    ./networking.nix
    ./nginx-check.nix
    ./nix.nix
    ./oomd.nix
    ./ssh.nix
  ];
  config = {
    ramona.roles = ["all"];
  };
}
