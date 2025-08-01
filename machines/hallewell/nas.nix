_: {
  imports = import ../../libs/nix/nix-files-from-dir.nix ./nas;
  config = {
    users.users.nas = {
      isSystemUser = true;
      uid = 16969;
      group = "nas";
    };
    users.groups.nas = {};
  };
}
