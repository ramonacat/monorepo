_: {
  imports =
    [
      ../roles/all.nix
      ../roles/private.nix
      ../roles/installed.nix

      ../users/ramona/installed.nix
      ../users/root/installed.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./shadowsoul);
}
