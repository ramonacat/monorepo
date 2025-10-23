{
  config,
  pkgs,
  ...
}: {
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
      importPath = "${paths.hallewell.nas-share}/PhotoprismImport/";
      address = "0.0.0.0";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [2342];

    services.restic.backups.photoprism = let
      path = "${paths.hallewell.nas-root}/photoprism/";
      backup-path = "${paths.hallewell.nas-root}/photoprism-backup/";
    in
      import ../../libs/nix/mk-restic-config.nix {inherit config pkgs;} {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          RandomizedDelaySec = "15m";
        };
        paths = [
          backup-path
        ];
        backupPrepareCommand = ''
          ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot "${path}" "${backup-path}"
        '';
        backupCleanupCommand = ''

          ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete "${backup-path}"
        '';
      };
  };
}
