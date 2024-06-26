{config, ...}: {
  config = {
    age.secrets.minio-tempo = {
      file = ../../secrets/minio-tempo.age;
      group = "tempo-secrets";
      mode = "440";
    };

    users = {
      groups.tempo-secrets = {};
      groups.tempo = {};
      users.tempo = {
        group = "tempo";
        isSystemUser = true;
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d '/var/tempo' - tempo tempo - -"
      ];

      services.tempo.serviceConfig = {
        EnvironmentFile = config.age.secrets.minio-tempo.path;
        BindPaths = "/var/tempo";
        User = "tempo";
      };
    };
    services.tempo = {
      enable = true;

      settings = {
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = 8989;
          grpc_listen_address = "0.0.0.0";
        };
        distributor = {
          receivers = {
            otlp = {
              protocols = {
                "grpc" = {};
                "http" = {};
              };
            };
          };
        };
        storage = {
          trace = {
            backend = "s3";
            s3 = {
              bucket = "tempo";
              endpoint = "localhost:9000";
              insecure = true;
            };
          };
        };
      };
    };
  };
}
