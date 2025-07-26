{nixpkgs}: {...}: {
  imports = [
    (import ./_all.nix {inherit nixpkgs;})

    ./_notlive.nix
    ./shadowsoul/hardware.nix
    ./shadowsoul/networking.nix
    ./shadowsoul/transmission.nix

    ../users/ramona/installed.nix
    ../users/root/base.nix
  ];
}
