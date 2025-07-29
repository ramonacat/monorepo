_: {
  imports = [
    ./_all.nix
    ./_notlive.nix

    ./shadowsoul/hardware.nix
    ./shadowsoul/networking.nix
    ./shadowsoul/transmission.nix

    ../users/ramona/installed.nix
    ../users/root/base.nix
  ];
}
