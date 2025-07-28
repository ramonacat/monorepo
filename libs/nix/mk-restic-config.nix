config: options:
{
  # TODO rename the bucket and secrets - this is the common config for all backups, not just postgres
  repository = "b2:ramona-postgres-backups:/common/";
  rcloneConfigFile = config.age.secrets."postgres-backups-rclone".path;
  environmentFile = config.age.secrets."postgres-backups-env".path;
  passwordFile = config.age.secrets."restic-repository-password".path;
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
