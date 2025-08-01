{modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")

    ../roles/all.nix
    ../roles/installed.nix

    ./crimson/disko.nix
    ./crimson/hardware.nix
    ./crimson/networking.nix
    ./crimson/nginx.nix

    ../users/ramona/installed.nix
    ../users/root/base.nix
  ];
}
