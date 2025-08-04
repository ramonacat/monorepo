{config, ...}: {
  config = {
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
