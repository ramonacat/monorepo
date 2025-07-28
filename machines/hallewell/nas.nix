_: {
  imports = [
    ./nas/backup.nix
    ./nas/samba.nix
    ./nas/nfs.nix
    ./nas/jellyfin.nix
  ];
  config = {
    users.users.nas = {
      isSystemUser = true;
      uid = 16969;
      group = "nas";
    };
    users.groups.nas = {};
  };
}
