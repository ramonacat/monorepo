_: {
  imports =
    [
      ../roles/all.nix
      ../roles/installed.nix
      ../roles/hetzner-cloud.nix

      ../users/ramona/installed.nix
      ../users/root/base.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./crimson);
}
