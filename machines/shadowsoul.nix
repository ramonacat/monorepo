_: {
  imports =
    [
      ../roles/all.nix
      ../roles/installed.nix
      ../roles/private.nix

      ../users/ramona/installed.nix
      ../users/root/installed.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./shadowsoul);
}
