{config, ...}: {
  config = {
    services.restic.backups.nas = {
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
      repository = "sftp:root@blackwood:/var/backups/${config.networking.hostName}/";
      passwordFile = config.age.secrets."restic-repository-password".path;
      paths = [
        "/mnt/nas3/data/"
      ];
      pruneOpts = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
        "--keep-yearly 100"
      ];
    };
  };
}
