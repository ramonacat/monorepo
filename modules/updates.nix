{ pkgs, config, ... }: {
  config = {
    age.secrets.universal-root = {
      file = ../secrets/universal-root.age;
    };
    systemd.services.updater = {
      after = [ "network.target" ];
      description = "Download the latest system closure";
      serviceConfig =
        let
          updaterScript = pkgs.writeScript "updater" ''
            #!${pkgs.stdenv.shell}
            set -x
            set -euo pipefail

            CLOSURE=$(${pkgs.curl}/bin/curl "https://ramona.fun/builds/${config.networking.hostName}-closure")
            PATH="${pkgs.openssh}/bin:$PATH" NIX_SSHOPTS="-i ${config.age.secrets.universal-root.path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ${pkgs.nix}/bin/nix-copy-closure --from root@caligari "$CLOSURE"
          '';
        in
        {
          Type = "oneshot";
          ExecStart = "${updaterScript}";
        };
    };

    systemd.timers.updater = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
        Unit = "updater.service";
      };
    };
  };
}
