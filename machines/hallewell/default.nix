_: {
  imports =
    [
      ../../roles/all
      ../../roles/installed
      ../../roles/private

      ../../users/ramona/installed
      ../../users/root/installed
    ]
    ++ (import ../../libs/nix/nix-files-from-dir.nix ./.);
}
