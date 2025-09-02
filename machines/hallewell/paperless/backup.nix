{config, ...}: {
  config = {
    services.restic.backups.paperless = let
      paths = import ../../../data/paths.nix;
    in
      import ../../../libs/nix/mk-restic-config.nix config {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          RandomizedDelaySec = "30m";
        };
        paths = [
          paths.hallewell.paperless
        ];
      };
  };
}
