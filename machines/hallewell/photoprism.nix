{config, ...}: {
  age.secrets.photoprism-password = {
    file = ../../secrets/photoprism-password.age;
    group = "photoprism";
    mode = "440";
  };

  services.photoprism = {
    enable = true;
    passwordFile = config.age.secrets.photoprism-password.path;
    storagePath = "/mnt/nas3/photoprism/storage/";
    originalsPath = "/mnt/nas3/photoprism/originals/";
    importPath = "/mnt/nas3/data/PhotoprismImport/";
    address = "0.0.0.0";
  };

  services.restic.backups.photoprism = let
    backupPath = "/mnt/nas3/photoprism/";
  in {
    timerConfig = {
      OnCalendar = "*-*-* 00/1:00:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
    repository = "b2:ramona-postgres-backups:/hallewell/";
    rcloneConfigFile = config.age.secrets."postgres-backups-rclone".path;
    environmentFile = config.age.secrets."postgres-backups-env".path;
    passwordFile = config.age.secrets."restic-repository-password".path;
    paths = [
      backupPath
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
      "--keep-yearly 100"
    ];
  };
}
