{
  config,
  pkgs,
  ...
}: {
  config = {
    services.restic.backups.mysql = let
      backups-path = "/tmp/mysql-backup/";
    in
      import ../../libs/nix/mk-restic-config.nix config {
        timerConfig = {
          OnCalendar = "*-*-* 00/6:00:00";
          RandomizedDelaySec = "3h";
        };
        backupPrepareCommand = ''
          mkdir "${backups-path}"
          chown mysql:mysql "${backups-path}"
          ${pkgs.mariadb}/bin/mysqldump --all-databases --user backup > ${backups-path}/dump.sql
        '';
        backupCleanupCommand = ''
          rm -r "${backups-path}" || true
        '';
        paths = [backups-path];
      };
  };
}
