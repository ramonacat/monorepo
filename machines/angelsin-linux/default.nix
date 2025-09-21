{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd

    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/workstation

    ./hardware.nix
    ./networking.nix
  ];
  config = {
    ramona.machine.location = "roaming";
  };
}
