{modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")

    ./disko.nix
    ./hardware.nix
  ];
  config = {
    ramona.roles = ["hetzner-cloud"];
  };
}
