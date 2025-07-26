{nixpkgs}: {...}: {
  imports = [
    (import ./_all.nix {inherit nixpkgs;})

    ./iso/filesystems.nix

    ../users/ramona/base.nix
    ../users/root/base.nix
  ];
}
