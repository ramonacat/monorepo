config: options: let
  repository =
    if config.ramona.machine.hasPublicIP
    then "public"
    else "common";
  bucket =
    if config.ramona.machine.hasPublicIP
    then "ramona-public-backups"
    else "ramona-postgres-backups";
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
