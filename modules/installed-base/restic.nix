{config, ...}: {
  config = {
    age.secrets = {
      postgres-backups-rclone = {
        file = ../../secrets/postgres-backups-rclone.age;
      };

      postgres-backups-env = {
        file = ../../secrets/postgres-backups-env.age;
      };

      restic-repository-password = {
        file = ../../secrets/restic-repository-password.age;
      };
    };

    services.restic.backups.home = {
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
      repository = "b2:ramona-postgres-backups:/${config.networking.hostName}/";
      rcloneConfigFile = config.age.secrets."postgres-backups-rclone".path;
      environmentFile = config.age.secrets."postgres-backups-env".path;
      passwordFile = config.age.secrets."restic-repository-password".path;
      paths = [
        "/home/"
      ];
      pruneOpts = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
        "--keep-yearly 3"
      ];
    };
  };
}
