_: {
  imports = [
    ../roles/all.nix
    ../roles/private.nix
    ../roles/installed.nix

    ./shadowsoul/hardware.nix
    ./shadowsoul/networking.nix
    ./shadowsoul/transmission.nix

    ../users/ramona/installed.nix
    ../users/root/base.nix
  ];
}
