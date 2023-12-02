{ config, pkgs, lib, ... }:
{
  config = {
    age.secrets.telegraf-database = {
      file = ../../secrets/telegraf-database.age;
      group = "telegraf";
      mode = "440";
    };

    services.telegraf = {
      enable = true;
      environmentFiles = [ config.age.secrets.telegraf-database.path ];
      extraConfig = {
        agent.omit_hostname = false;
        outputs.postgresql = {
          connection = "postgres://telegraf:$DB_PASSWORD@hallewell/telegraf";
          tags_as_foreign_keys = true;
          timestamp_column_type = "timestamp with time zone";
          tag_cache_size = 100000;
        };
        inputs.cpu = {};
        inputs.disk = {};
        inputs.diskio = {};
        inputs.ethtool = {};
      };
    };
  };
}
