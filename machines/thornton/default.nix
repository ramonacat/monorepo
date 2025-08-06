_: {
  imports =
    [
      ../../roles/all
      ../../roles/hetzner-cloud
      ../../roles/installed
      ../../roles/server-public

      ../../users/ramona/installed
      ../../users/root/installed
    ]
    ++ (import ../../libs/nix/nix-files-from-dir.nix ./.);
}
