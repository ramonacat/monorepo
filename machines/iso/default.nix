{inputs, ...}: {
  imports = [
    inputs.nixos-generators.nixosModules.all-formats

    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../../roles/all

    ../../modules/machine-kind.nix

    ../../users/ramona/base
    ../../users/root/base

    ./filesystems.nix
  ];
  config = {
    ramona.machine.type = "live";
  };
}
