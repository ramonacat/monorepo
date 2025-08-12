{pkgs, ...}: {
  imports = [
    ./backup.nix
  ];
  config = {
    services.mysql = {
      enable = true;
      package = pkgs.mysql84;
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
