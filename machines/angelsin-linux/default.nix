{inputs, ...}: {
  imports =
    [
      inputs.nixos-hardware.nixosModules.framework-13-7040-amd

      ../../roles/all
      ../../roles/installed
      ../../roles/private
      ../../roles/workstation

      ../../users/ramona/installed
      ../../users/root/installed
    ]
    ++ import ../../libs/nix/nix-files-from-dir.nix ./.;
}
