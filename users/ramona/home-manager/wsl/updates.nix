{
  pkgs,
  config,
  ...
}: {
  config = {
    systemd.user.services.updater = {
      Unit = {
        Description = "Download the latest home closure";
        # This is so that the service won't be stopped during the update (which would break things, as the update will never finish)
        RefuseManualStop = true;
        RefuseManualStart = true;
      };
      Service = let
        updaterScript = pkgs.writeScript "updater" ''
          #!${pkgs.stdenv.shell}
          set -x
          set -euo pipefail

          if [[ -f "${config.home.homeDirectory}/.stop_updates" ]]; then
              echo "Updates are stopped. Remove ${config.home.homeDirectory}/.stop_updates to reenable";
              exit;
          fi;

          CURRENT_USER_CLOSURE=$(readlink -f ${config.home.homeDirectory}/.local/state/nix/profiles/home-manager)
          CLOSURE=$(${pkgs.curl}/bin/curl "https://hallewell.ibis-draconis.ts.net/builds/${config.home.username}-wsl-home" | tr -d '\n')

          if [[ "$CLOSURE" == "$CURRENT_USER_CLOSURE" ]]; then
              echo "System already running the latest closure, not rebuilding";
              exit;
          fi;

          ${pkgs.nix}/bin/nix-store --realise "$CLOSURE"
          $CLOSURE/bin/home-manager-generation
          ${pkgs.nix}/bin/nix-env --profile ${config.home.homeDirectory}/.local/state/nix/profiles/home-manager --set $CLOSURE
        '';
      in {
        Type = "oneshot";
        ExecStart = "${updaterScript}";
      };
    };

    systemd.user.timers.updater = {
      Install = {
        WantedBy = ["timers.target"];
      };
      Timer = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        Unit = "updater.service";
      };
    };
  };
}
