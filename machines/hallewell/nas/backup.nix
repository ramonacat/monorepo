{config, ...}: {
  config = {
    services.restic.backups.nas = {
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
      repository = "b2:ramona-postgres-backups:/hallewell/";
      rcloneConfigFile = config.age.secrets."postgres-backups-rclone".path;
      environmentFile = config.age.secrets."postgres-backups-env".path;
      passwordFile = config.age.secrets."restic-repository-password".path;
      paths = [
        "/mnt/nas3/data/"
      ];
      exclude = [
        "/mnt/nas3/data/Movies/"
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
