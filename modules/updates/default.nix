{
  pkgs,
  lib,
  flake,
  config,
  ...
}:
{
  options = {
    ramona.updates =
      with lib.types;
      lib.mkOption {
        type = submodule {
          options = {
            enable = lib.mkOption {
              default = true;
              type = bool;
            };
            mode = lib.mkOption {
              default = "switch";
              type = enum [
                "switch"
                "boot"
              ];
            };
            post-update = lib.mkOption {
              default = "";
              type = str;
            };
          };
        };
      };
  };
  config = {
    systemd = lib.mkIf config.ramona.updates.enable {
      services.updater = {
        description = "Download the latest system closure";
        restartIfChanged = false;
        serviceConfig =
          let
            post-update = pkgs.writeShellScriptBin "post-update" config.ramona.updates.post-update;
            updater-script = pkgs.stdenvNoCC.mkDerivation {
              name = "updater";
              src = ./scripts;
              nativeBuildInputs = with pkgs; [ makeWrapper ];
              installPhase = ''
                mkdir --parents $out/bin/

                cp updates.bash $out/bin/

                wrapProgram $out/bin/updates.bash \
                    --set UPDATES_LIB '${../../scripts/lib/updates.bash}' \
                    --set UPDATES_MODE '${config.ramona.updates.mode}' \
                    --set UPDATES_POST '${post-update}/bin/post-update' \
                    --set BUILDERS '${builtins.toJSON flake.hosts.builds-hosts}' \
                    --prefix PATH : ${
                      lib.makeBinPath (
                        with pkgs;
                        [
                          curl
                          nix
                          jq
                        ]
                      )
                    }
              '';
            };
          in
          {
            Type = "oneshot";
            ExecStart = "${updater-script}/bin/updates.bash";
          };
      };

      timers.updater = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1m";
          OnUnitActiveSec = "1m";
          Unit = "updater.service";
        };
      };
    };
  };
}
