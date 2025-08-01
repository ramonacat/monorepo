{modulesPath, ...}: {
  imports =
    [
      (modulesPath + "/profiles/qemu-guest.nix")

      ../roles/all.nix
      ../roles/installed.nix

      ../users/ramona/installed.nix
      ../users/root/base.nix
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./crimson);
}
