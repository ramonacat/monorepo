{pkgs, ...}: {
  imports = [
    ./backup.nix
  ];
  config = {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureUsers = [
        {
          name = "backup";
          ensurePermissions = {
            "*.*" = "SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, PROCESS, RELOAD";
          };
        }
      ];
    };
  };
}
