{config, ...}: {
  config = {
    # TODO move the secrets setup to its own nix file
    age.secrets = {
      backups-rclone = {
        file = ../../secrets/backups-rclone.age;
      };

      backups-env = {
        file = ../../secrets/backups-env.age;
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
