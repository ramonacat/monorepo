{inputs, ...}: {
  imports =
    [
      inputs.nixos-generators.nixosModules.all-formats

      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ../../roles/all

      ../../users/ramona/base
      ../../users/root/base
    ]
    ++ (import ../../libs/nix/nix-files-from-dir.nix ./.);
}
