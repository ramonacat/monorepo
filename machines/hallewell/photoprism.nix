{config, ...}: {
  config = let
    paths = import ../../data/paths.nix;
  in {
    age.secrets.photoprism-password = {
      file = ../../secrets/photoprism-password.age;
      group = "photoprism";
      mode = "440";
    };

    services.photoprism = {
      enable = true;
      passwordFile = config.age.secrets.photoprism-password.path;
      storagePath = "${paths.hallewell.nas-root}/photoprism/storage/";
      originalsPath = "${paths.hallewell.nas-root}/photoprism/originals/";
      importPath = "${paths.hallewell.nas-share}/data/PhotoprismImport/";
      address = "0.0.0.0";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [2342];

    services.restic.backups.photoprism = let
      backupPath = "${paths.hallewell.nas-root}/photoprism/";
    in
      {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
        paths = [
          backupPath
        ];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 3"
          "--keep-yearly 3"
        ];
      }
      // import ../../libs/nix/mk-restic-repository.nix config "hallewell";
  };
}
