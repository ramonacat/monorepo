{
  config,
  pkgs,
  ...
}: {
  config = {
    services.restic.backups.immich = let
      paths = import ../../../data/paths.nix;
    in
      import ../../../libs/nix/mk-restic-config.nix {inherit config pkgs;} (let
        immich-path = paths.hallewell.immich;
        backup-path = "${immich-path}-backup";
      in {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          RandomizedDelaySec = "30m";
        };
        paths = [
          backup-path
        ];
        backupPrepareCommand = ''
          ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot "${immich-path}" "${backup-path}"
        '';
        backupCleanupCommand = ''
          ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete "${backup-path}"
        '';
      });
  };
}
