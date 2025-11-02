{
  config,
  pkgs,
  ...
}: {
  config = {
    services.restic.backups.jellyfin = let
      paths = import ../../../data/paths.nix;
    in
      import ../../../libs/nix/mk-restic-config.nix {inherit config pkgs;} (let
        path = paths.hallewell.jellyfin;
        backup-path = "${path}-backup";
      in {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          RandomizedDelaySec = "30m";
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
      });
  };
}
