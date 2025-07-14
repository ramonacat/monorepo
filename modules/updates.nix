{
  pkgs,
  config,
  ...
}: {
  config = {
    age.secrets.universal-root = {
      file = ../secrets/universal-root.age;
    };
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
          CLOSURE=$(${pkgs.curl}/bin/curl "https://ramona.fun/builds/${config.networking.hostName}-closure" | tr -d '\n')

          if [[ "$CLOSURE" == "$CURRENT_SYSTEM_CLOSURE" ]]; then
              echo "System already running the latest closure, not rebuilding";
              exit;
          fi;

          PATH="${pkgs.openssh}/bin:$PATH" NIX_SSHOPTS="-i ${config.age.secrets.universal-root.path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ${pkgs.nix}/bin/nix-copy-closure --from root@blackwood "$CLOSURE"
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
