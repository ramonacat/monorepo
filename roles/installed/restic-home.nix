{
  pkgs,
  config,
  ...
}: {
  config = {
    services.restic.backups.home =
      (import ../../libs/nix/mk-restic-config.nix) {inherit pkgs config;}
      {
        timerConfig = {
          OnCalendar = "*-*-* 00/6:00:00";
          RandomizedDelaySec = "3h";
        };
        paths = [
          "/home/"
        ];
      };
  };
}
