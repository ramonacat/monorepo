{
  pkgs,
  lib,
  flake,
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
        updaterScript = pkgs.stdenvNoCC.mkDerivation {
          name = "updater";
          src = ./scripts;
          nativeBuildInputs = with pkgs; [makeWrapper];
          installPhase = ''
            mkdir --parents $out/bin/

            cp updates.bash $out/bin/

            wrapProgram $out/bin/updates.bash \
                --set UPDATES_LIB '${../../../../../scripts/lib/updates.bash}' \
                --set BUILDERS '${builtins.toJSON flake.hosts.builds-hosts}' \
                --prefix PATH : ${lib.makeBinPath (with pkgs; [curl nix jq])}
          '';
        };
      in {
        Type = "oneshot";
        ExecStart = "${updaterScript}/bin/updates.bash";
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
