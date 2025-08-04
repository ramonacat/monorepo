config: options: let
  repository =
    if config.ramona.machine.visibility == "private"
    then "common"
    else "public";
  bucket =
    if config.ramona.machine.visibility == "private"
    then "ramona-postgres-backups"
    else "ramona-public-backups";
in
  {
    repository = "b2:${bucket}:/${repository}/";
    rcloneConfigFile = config.age.secrets."backups-${repository}-rclone".path;
    environmentFile = config.age.secrets."backups-${repository}-env".path;
    passwordFile = config.age.secrets."backups-${repository}-password".path;
    timerConfig = {
      Persistent = true;
    };
    pruneOpts = [
      "--keep-hourly 24"
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
      "--keep-yearly 3"
    ];
    extraOptions = ["--retry-lock=5m"];
  }
  // options
