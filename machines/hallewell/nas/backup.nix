{config, ...}: {
  config = {
    services.restic.backups.nas = {
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
      repository = "sftp:u401821@u401821.your-storagebox.de:${config.networking.hostName}/";
      passwordFile = config.age.secrets."restic-repository-password".path;
      paths = [
        "/home/"
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
