{
  pkgs,
  config,
  ...
}: {
  config = {
    systemd.services.updater = {
      description = "Download the latest system closure";
      restartIfChanged = false;
      serviceConfig = let
        updaterScript = pkgs.writeScript "updater" ''
          #!${pkgs.stdenv.shell}
          set -x
          set -euo pipefail

          if [[ -f "/var/.stop_updates" ]]; then
              echo "Updates are stopped. Remove /var/.stop_updates to reenable";
              exit;
          fi;

          CURRENT_SYSTEM_CLOSURE=$(readlink -f /nix/var/nix/profiles/system)
          CLOSURE=$(${pkgs.curl}/bin/curl "https://thornton.ibis-draconis.ts.net/builds/${config.networking.hostName}-closure" | tr -d '\n')

          if [[ "$CLOSURE" == "$CURRENT_SYSTEM_CLOSURE" ]]; then
              echo "System already running the latest closure, not rebuilding";
              exit;
          fi;

          ${pkgs.nix}/bin/nix-store --realise "$CLOSURE"
          $CLOSURE/bin/switch-to-configuration switch
          ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set $CLOSURE
        '';
      in {
        Type = "oneshot";
        ExecStart = "${updaterScript}";
      };
    };

    systemd.timers.updater = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        Unit = "updater.service";
      };
    };
  };
}
