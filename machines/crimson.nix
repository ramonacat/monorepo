{modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")

    ./_all.nix
    ./_notlive.nix

    ./crimson/disko.nix
    ./crimson/hardware.nix
    ./crimson/networking.nix

    ../users/ramona/installed.nix
    ../users/root/base.nix
  ];
}
