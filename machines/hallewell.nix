_: {
  imports =
    [
      ../roles/all.nix
      ../roles/private.nix
      ../roles/installed.nix

      ../users/ramona/installed.nix
      ../users/root/base.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./hallewell);
}
