{ inputs, ... }: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../../roles/all

    ../../modules/machine-kind.nix

    ./filesystems.nix
  ];
  config = {
    ramona.machine.type = "live";
    isoImage.edition = "ramona";
  };
}
