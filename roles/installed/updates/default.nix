{
  pkgs,
  lib,
  flake,
  ...
}: {
  config = {
    systemd.services.updater = {
      description = "Download the latest system closure";
      restartIfChanged = false;
      serviceConfig = let
        updaterScript = pkgs.stdenvNoCC.mkDerivation {
          name = "updater";
          src = ./scripts;
          nativeBuildInputs = with pkgs; [makeWrapper];
          installPhase = ''
            mkdir --parents $out/bin/

            cp updates.bash $out/bin/

            wrapProgram $out/bin/updates.bash \
                --set UPDATES_LIB '${../../../scripts/lib/updates.bash}' \
                --set BUILDERS '${builtins.toJSON flake.hosts.builds-hosts}' \
                --prefix PATH : ${lib.makeBinPath (with pkgs; [curl nix jq])}
          '';
        };
      in {
        Type = "oneshot";
        ExecStart = "${updaterScript}/bin/updates.bash";
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
