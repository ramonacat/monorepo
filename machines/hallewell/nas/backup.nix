{
  config,
  pkgs,
  ...
}: {
  config = {
    services.restic.backups.nas = let
      paths = import ../../../data/paths.nix;
    in
      import ../../../libs/nix/mk-restic-config.nix {inherit config pkgs;} {
        timerConfig = {
          OnCalendar = "*-*-* 00/1:00:00";
          RandomizedDelaySec = "30m";
        };
        paths = [
          paths.hallewell.nas-share
        ];
        exclude = [
          "${paths.hallewell.nas-share}/Movies/"
        ];
      };
  };
}
