{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];
  options = {
    services.ramona.minecraft = lib.mkOption {
      description = "A minecraft server with ramona-standard configuration";
      default = {};
      type = with lib.types;
        attrsOf (submodule {
          options = {
            port = lib.mkOption {type = port;};
            rconPort = lib.mkOption {type = port;};
            whitelist = lib.mkOption {
              type = attrsOf str;
            };
          };
        });
    };
  };
  config = let
    servers = config.services.ramona.minecraft;
  in {
    services.minecraft-servers = {
      enable = true;
      eula = true;

      # Do not let the module open firewall ports, because it will open also the RCON port, which should be local-only in our case
      openFirewall = false;

      servers =
        lib.mapAttrs
        (_: settings: {
          enable = true;
          openFirewall = false;
          inherit (settings) whitelist;
          # stolen from https://docs.papermc.io/paper/aikars-flags
          jvmOpts = "-Xms4G -Xmx4G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1";
          serverProperties = {
            server-port = settings.port;
            white-list = true;
            enable-rcon = true;
            "rcon.port" = settings.rconPort;
            "rcon.password" = "rcon";
          };
          package = pkgs.minecraftServers.vanilla;
        })
        servers;
    };

    services.restic.backups =
      lib.mapAttrs' (name: settings: let
        path = "${config.services.minecraft-servers.dataDir}/${name}";
        backupPath = "${path}-backup";
      in {
        name = "minecraft-" + name;
        value = let
          informerScript = pkgs.writeShellScriptBin ("backup-minecraft-server-" + name) "
          #!/usr/bin/env bash

          set -euo pipefail

          ${pkgs.rcon-cli}/bin/rcon-cli --host localhost --port ${toString settings.rconPort} --password rcon 'say [§4WARNING§r] starting server backup'
        ";
        in
          import ../libs/nix/mk-restic-config.nix {inherit config pkgs;} {
            timerConfig = {
              OnCalendar = "*-*-* *:00:00";
              RandomizedDelaySec = "30min";
            };
            backupPrepareCommand = ''
              ${informerScript}/bin/backup-minecraft-server-${name}

              ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot ${path} ${backupPath}
            '';
            backupCleanupCommand = ''
              ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete ${backupPath}
            '';
            paths = [backupPath];
          };
      })
      servers;

    networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: settings: settings.port) servers;
  };
}
