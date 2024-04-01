{config, ...}: {
  config = {
    age.secrets = {
      caligari-minecraft-rclone-config = {
        file = ../../secrets/caligari-minecraft-rclone-config.age;
      };

      "caligari-postgres-backups-env" = {
        file = ../../secrets/caligari-postgres-backups-env.age;
      };

      "caligari-postgres-backups-rclone" = {
        file = ../../secrets/caligari-postgres-backups-rclone.age;
      };

      "restic-repository-password.age" = {
        file = ../../secrets/restic-repository-password.age;
      };
    };

    services.ramona.minecraft = let
      backupSettings = {
        resticRepository = "b2:ramona-postgres-backups:/caligari/";
        resticEnvironmentFile = config.age.secrets."caligari-postgres-backups-env".path;
        resticRcloneConfigFile = config.age.secrets."caligari-postgres-backups-rclone".path;
        resticPasswordFile = config.age.secrets."restic-repository-password.age".path;
      };
    in {
      gierki =
        {
          port = 43000;
          rconPort = 25575;
          whitelist = {
            Agares2 = "2535f2de-9174-4bc5-8bdf-233649bc0449";
            GayEmoPirate = "f14060b2-1b7a-436e-bb09-c7c693b4503b";
          };
        }
        // backupSettings;
      luczkiewy =
        {
          port = 43001;
          rconPort = 25576;
          whitelist = {
            Agares2 = "2535f2de-9174-4bc5-8bdf-233649bc0449";
            GayEmoPirate = "f14060b2-1b7a-436e-bb09-c7c693b4503b";
            Franciszek_IX = "5e038352-818b-49b2-9221-7ab46e4caf15";
            MarthaLee = "e45960c1-61cb-4a10-a20b-9bbf3926602f";
            CleanUpGuyPL = "8a1b4570-0cc4-47ed-8cbc-a8c14e7e51ff";
          };
        }
        // backupSettings;
    };
  };
}
