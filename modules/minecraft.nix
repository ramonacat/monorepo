{
  lib,
  pkgs,
  config,
  ...
}: {
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
            resticRcloneConfigFile = lib.mkOption {type = path;};
            resticEnvironmentFile = lib.mkOption {type = path;};
            resticPasswordFile = lib.mkOption {type = path;};
            resticRepository = lib.mkOption {type = str;};
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
          package = pkgs.minecraftServers.vanilla-1_21_4;
        })
        servers;
    };

    services.restic.backups =
      lib.mapAttrs' (name: settings: let path = "/mnt/nas3/minecraft/${name}/"; backupPath = "/mnt/nas3/minecraft/${name}-backup/"; in {
          name = "minecraft-" + name;
          value = let
            informerScript = pkgs.writeShellScriptBin ("backup-minecraft-server-" + name) "
          #!/usr/bin/env bash

          set -euo pipefail
          set -x

          ${pkgs.rcon}/bin/rcon -H localhost -p ${toString settings.rconPort} -P rcon <<EOS
            say [§4WARNING§r] starting server backup
EOS
        ";
          in {
            timerConfig = {
              OnCalendar = "*-*-* *:00:00";
              Persistent = true;
              RandomizedDelaySec = "30min";
            };
            extraOptions = ["--retry-lock"];
            repository = settings.resticRepository;
            rcloneConfigFile = settings.resticRcloneConfigFile;
            environmentFile = settings.resticEnvironmentFile;
            passwordFile = settings.resticPasswordFile;
            backupPrepareCommand = ''
              ${informerScript}/bin/backup-minecraft-server-${name}

              ${pkgs.bcachefs-tools}/bin/bcachefs subvolume snapshot ${path} ${backupPath}
            '';
            backupCleanupCommand = ''
              ${pkgs.bcachefs-tools}/bin/bcachefs subvolume delete ${backupPath}
            '';
            paths = [backupPath];
            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 3"
              "--keep-yearly 3"
            ];
          };
        })
      servers;

    networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: settings: settings.port) servers;
  };
}
