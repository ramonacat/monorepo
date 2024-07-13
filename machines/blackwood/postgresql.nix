{
  config,
  pkgs,
  ...
}: let
  postgresPackage = pkgs.postgresql_16;
in {
  config = {
    services = {
      postgresql = {
        enable = true;
        enableJIT = true;

        authentication = ''
          #type database    DBuser  addresss    auth-method
          local all         all                 trust
          local replication all                 trust
          host  all         all     100.0.0.0/8 scram-sha-256
        '';

        package = postgresPackage;
        dataDir = "/var/lib/postgresql/16/";
        initdbArgs = ["--data-checksums"];
        enableTCPIP = true;
        settings = {
          wal_level = "replica";
          shared_preload_libraries = "pg_stat_statements,auto_explain";
          "pg_stat_statements.track" = "all";
          "auto_explain.log_min_duration" = "250ms";
        };
      };
      telegraf.extraConfig.inputs.postgresql = {
        address = "postgres://telegraf:$DB_PASSWORD@localhost/telegraf";
      };

      restic.backups.postgresql = let
        backupPath = "/var/lib/postgres-backup-16";
      in {
        timerConfig = {
          OnCalendar = "*-*-* 00/6:00:00";
          Persistent = true;
          RandomizedDelaySec = "3h";
        };
        repository = "b2:ramona-postgres-backups:/caligari/";
        rcloneConfigFile = config.age.secrets."postgres-backups-rclone".path;
        environmentFile = config.age.secrets."postgres-backups-env".path;
        backupPrepareCommand = ''
          mkdir ${backupPath}
          chown postgres:postgres ${backupPath}
          ${pkgs.sudo}/bin/sudo -u postgres ${postgresPackage}/bin/pg_basebackup -Xstream -D${backupPath}
        '';
        backupCleanupCommand = ''
          rm -r ${backupPath} || true
        '';
        passwordFile = config.age.secrets."restic-repository-password".path;
        paths = [
          backupPath
        ];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 3"
          "--keep-yearly 100"
        ];
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [5432];
  };
}
