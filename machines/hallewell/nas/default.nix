_: {
  imports = [
    ./backup.nix
    ./nfs.nix
    ./samba.nix
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
