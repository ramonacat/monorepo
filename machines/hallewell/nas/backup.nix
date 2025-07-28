{config, ...}: {
  config = {
    services.restic.backups.nas = let
      paths = import ../../../data/paths.nix;
    in
      {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
        paths = [
          paths.hallewell.nas-share
        ];
        exclude = [
          "${paths.hallewell.nas-share}/Movies/"
        ];
        pruneOpts = [
          "--keep-hourly 24"
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 3"
          "--keep-yearly 3"
        ];
      }
      // import ../../../libs/nix/mk-restic-repository.nix config "hallewell";
  };
}
