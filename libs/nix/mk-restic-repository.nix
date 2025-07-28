config: hostname: {
  repository = "b2:ramona-postgres-backups:/${hostname}/";
  rcloneConfigFile = config.age.secrets."postgres-backups-rclone".path;
  environmentFile = config.age.secrets."postgres-backups-env".path;
  passwordFile = config.age.secrets."restic-repository-password".path;
}
