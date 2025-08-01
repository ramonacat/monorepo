_: {
  imports =
    [
      ../roles/all.nix

      ../users/ramona/base.nix
      ../users/root/base.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./iso);
}
