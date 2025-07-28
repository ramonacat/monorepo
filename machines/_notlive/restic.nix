{config, ...}: {
  config = {
    # TODO move the secrets setup to its own nix file
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

    services.restic.backups.home =
      import ../../libs/nix/mk-restic-config.nix config
      {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          RandomizedDelaySec = "30m";
        };
        paths = [
          "/home/"
        ];
      };
  };
}
