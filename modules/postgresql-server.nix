{
  pkgs,
  config,
  lib,
  ...
}: {
  options = {
    services.ramona.postgresql-server = lib.mkOption {
      description = "a postgresql server with backups";
      default = {};
      type = with lib.types;
        submodule {
          options = {
            enable = lib.mkOption {type = bool;};
            path = lib.mkOption {type = lib.types.string;};
            backup-path = lib.mkOption {type = lib.types.string;};
          };
        };
    };
  };

  config = let
    server = config.services.ramona.postgresql-server;
    postgresPackage = pkgs.postgresql_17;
  in
    lib.mkIf server.enable {
      services.postgresql = {
        enable = true;
        enableJIT = true;

        authentication = ''
          #type database    DBuser  addresss    auth-method
          local all         all                 trust
          local replication all                 trust
          host  all         all     100.0.0.0/8 scram-sha-256
        '';

        package = postgresPackage;
        dataDir = server.path;
        initdbArgs = ["--data-checksums"];
        enableTCPIP = true;
        settings = {
          wal_level = "replica";
          shared_preload_libraries = "pg_stat_statements,auto_explain";
          "pg_stat_statements.track" = "all";
          "auto_explain.log_min_duration" = "250ms";
        };
      };

      services.restic.backups.postgresql = let
        backupPath = server.backup-path;
      in
        import ../libs/nix/mk-restic-config.nix config {
          timerConfig = {
            OnCalendar = "*-*-* 00/6:00:00";
            RandomizedDelaySec = "3h";
          };
          backupPrepareCommand = ''
            mkdir ${backupPath}
            chown postgres:postgres ${backupPath}
            ${pkgs.sudo}/bin/sudo -u postgres ${postgresPackage}/bin/pg_basebackup -Xstream -D${backupPath}
          '';
          backupCleanupCommand = ''
            rm -r ${backupPath} || true
          '';
          paths = [
            backupPath
          ];
        };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [5432];
    };
}
