{modulesPath, ...}: {
  imports =
    [
      (modulesPath + "/profiles/qemu-guest.nix")
    ]
    ++ (import ../libs/nix/nix-files-from-dir.nix ./hetzner-cloud);
}
