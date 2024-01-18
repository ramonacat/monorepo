{ lib, modulesPath, pkgs, config, ... }:
{
  options = {
    services.ramona.minecraft = lib.mkOption {
      description = "A minecraft server with ramona-standard configuration";
      default = { };
      type = with lib.types; attrsOf (submodule {
        options = {
          port = lib.mkOption { type = port; };
          rconPort = lib.mkOption { type = port; };
          whitelist = lib.mkOption {
            type = attrsOf str;
          };
        };
      });
    };
  };
  config =
    let
      servers = config.services.ramona.minecraft;
    in
    {
      services.minecraft-servers = {
        enable = true;
        eula = true;

        # Do not let the module open firewall ports, because it will open also the RCON port, which should be local-only in our case
        openFirewall = false;

        servers = lib.mapAttrs
          (name: settings: {
            enable = true;
            openFirewall = false;
            whitelist = settings.whitelist;
            serverProperties = {
              server-port = settings.port;
              white-list = true;
              enable-rcon = true;
              "rcon.port" = settings.rconPort;
              "rcon.password" = "rcon";
            };
            package = pkgs.minecraftServers.vanilla-1_20_4;
          })
          servers;
      };

      systemd.services = lib.mapAttrs'
        (name: settings: {
          name = "backup-minecraft-" + name;
          value =
            let
              script = pkgs.writeShellScriptBin ("backup-minecraft-server-" + name) "
          #!/usr/bin/env bash

          set -euo pipefail
          set -x

          function cleanup {
              ${pkgs.rcon}/bin/rcon -H localhost -p ${toString settings.rconPort} -P rcon <<EOS
                save-on
                say [§bNOTICE§r] server backup finished
EOS
          }
          trap cleanup EXIT

          ${pkgs.rcon}/bin/rcon -H localhost -p ${toString settings.rconPort} -P rcon <<EOS
            say [§4WARNING§r] starting server backup
            save-off
            save-all
EOS
          ${pkgs.gnutar}/bin/tar -cf /tmp/${name}.tar /srv/minecraft/${name}/
          ${pkgs.rclone}/bin/rclone --config=${config.age.secrets.caligari-minecraft-rclone-config.path} --verbose copy /tmp/${name}.tar b2:ramona-minecraft-backups/
          rm /tmp/${name}.tar
        ";
            in
            {
              after = [ "network.target" ];
              description = "Backup the Minecraft server (${name})";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${script}/bin/backup-minecraft-server-${name}";
              };
            };
        })
        servers;

      systemd.timers = lib.mapAttrs'
        (name: settings: {
          name = "backup-minecraft-${name}";
          value = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "1h";
              OnUnitActiveSec = "1h";
              Unit = "backup-minecraft-${name}.service";
            };

          };
        })
        servers;

      networking.firewall.allowedTCPPorts = lib.mapAttrsToList (name: settings: settings.port) servers;
    };
}
