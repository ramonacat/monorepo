_: {
  imports = [
    ../roles/all.nix

    ./iso/filesystems.nix

    ../users/ramona/base.nix
    ../users/root/base.nix
  ];
}
