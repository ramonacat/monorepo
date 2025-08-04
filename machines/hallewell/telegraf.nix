{config, ...}: {
  config = {
    age.secrets.telegraf-database = {
      file = ../../secrets/telegraf-database.age;
      group = "telegraf";
      mode = "440";
    };

    services.telegraf = {
      environmentFiles = [
        config.age.secrets.telegraf-database.path
      ];
      extraConfig = {
        outputs.postgresql = {
          connection = "postgres://telegraf:$DB_PASSWORD@hallewell/telegraf";
          timestamp_column_type = "timestamp with time zone";
          tag_cache_size = 100000;
        };
        inputs = {
          socket_listener = {
            service_address = "tcp://:8094";
            content_encoding = "gzip";
            data_format = "influx";
          };
          file = let
            paths = import ../../data/paths.nix;
          in {
            files = ["${paths.hallewell.tailscale-www-root}/builds/*-closure"];
            data_format = "value";
            data_type = "string";
            name_override = "latest_closure";
            file_tag = "filename";
          };
        };
      };
    };
  };
}
