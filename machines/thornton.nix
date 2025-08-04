_: {
  imports =
    [
      ../roles/all.nix
      ../roles/hetzner-cloud.nix
      ../roles/installed.nix
      ../roles/public.nix

      ../users/ramona/installed.nix
      ../users/root/installed.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./thornton);
}
