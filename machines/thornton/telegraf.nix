{
  config,
  lib,
  ...
}: {
  config = let
    telegraf-tcp-port = 8094;
  in {
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
        outputs = lib.mkForce {
          postgresql = {
            connection = "postgres://telegraf:$DB_PASSWORD@thornton/telegraf";
            timestamp_column_type = "timestamp with time zone";
            tag_cache_size = 100000;
          };
        };
        inputs = {
          socket_listener = {
            service_address = "tcp://:${builtins.toString telegraf-tcp-port}";
            content_encoding = "gzip";
            data_format = "influx";
          };
        };
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [telegraf-tcp-port];
  };
}
