{config, ...}: {
  config = {
    services.restic.backups.nas =
      {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          Persistent = true;
          RandomizedDelaySec = "30m";
        };
        paths = [
          "/mnt/nas3/data/"
        ];
        exclude = [
          "/mnt/nas3/data/Movies/"
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
