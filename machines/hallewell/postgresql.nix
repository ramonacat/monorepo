{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    age.secrets."wal-g-config.env" = {
      file = ../../secrets/wal-g-config.env.age;
      group = "postgres";
      mode = "440";
    };

    services.postgresql = {
      enable = true;
      enableJIT = true;

      authentication = ''
        #type database  DBuser  addresss    auth-method
        local all       all                 trust
        host  all       all     100.0.0.0/8 scram-sha-256
      '';

      package = pkgs.postgresql_16;
      dataDir = "/mnt/nas3/postgresql/16/";
      initdbArgs = ["--data-checksums"];
      enableTCPIP = true;
      settings = {
        wal_level = "replica";
        archive_mode = "on";
        archive_command = "${pkgs.wal-g}/bin/wal-g --config ${config.age.secrets."wal-g-config.env".path} wal-push %p";
        shared_preload_libraries = "pg_stat_statements,auto_explain";
        "pg_stat_statements.track" = "all";
        "auto_explain.log_min_duration" = "250ms";
      };
    };

    services.telegraf.extraConfig.inputs.postgresql = {
      address = "postgres://telegraf:$DB_PASSWORD@hallewell/telegraf";
    };
  };
}
