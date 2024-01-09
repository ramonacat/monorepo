{ config, pkgs, lib, ... }:
{
  config = {
    age.secrets.caligari-minecraft-rclone-config = {
      file = ../../secrets/caligari-minecraft-rclone-config.age;
    };

    services.minecraft-servers = {
      enable = true;
      eula = true;

      # Do not let the module open firewall ports, because it will open also the RCON port, which should be local-only in our case
      openFirewall = false;

      servers = {
        gierki = {
          enable = true;
          openFirewall = false;
          whitelist = {
            Agares2 = "2535f2de-9174-4bc5-8bdf-233649bc0449";
            GayEmoPirate = "f14060b2-1b7a-436e-bb09-c7c693b4503b";
          };
          serverProperties = {
            server-port = 43000;
            white-list = true;
            enable-rcon = true;
            "rcon.port" = 25575;
            "rcon.password" = "rcon";
          };
          package = pkgs.minecraftServers.vanilla-1_20_4;
        };
        luczkiewy = {
          enable = true;
          openFirewall = false;
          whitelist = {
            Agares2 = "2535f2de-9174-4bc5-8bdf-233649bc0449";
            GayEmoPirate = "f14060b2-1b7a-436e-bb09-c7c693b4503b";
            Franciszek_IX = "5e038352-818b-49b2-9221-7ab46e4caf15";
            MarthaLee = "e45960c1-61cb-4a10-a20b-9bbf3926602f";
            CleanUpGuyPL = "8a1b4570-0cc4-47ed-8cbc-a8c14e7e51ff";
          };
          serverProperties = {
            server-port = 43001;
            white-list = true;
            enable-rcon = true;
            "rcon.port" = 25576;
            "rcon.password" = "rcon";
          };
          package = pkgs.minecraftServers.vanilla-1_20_4;
        };
      };
    };

    # Backups
    systemd.services.backup-minecraft-gierki =
      let
        script = pkgs.writeShellScriptBin "backup-minecraft-server-gierki" "
          #!/usr/bin/env bash

          set -euo pipefail
          set -x

          ${pkgs.rcon}/bin/rcon -H localhost -p 25575 -P rcon <<EOS
            say [§4WARNING§r] starting server backup
            save-off
            save-all
EOS
          ${pkgs.gnutar}/bin/tar -cf /tmp/gierki.tar /srv/minecraft/gierki/
          ${pkgs.rcon}/bin/rcon -H localhost -p 25575 -P rcon <<EOS
            save-on
            say [§bNOTICE§r] server backup finished
EOS
          ${pkgs.rclone}/bin/rclone --config=${config.age.secrets.caligari-minecraft-rclone-config.path} --verbose copy /tmp/gierki.tar b2:ramona-minecraft-backups/
          rm /tmp/gierki.tar
        ";
      in
      {
        after = [ "network.target" ];
        description = "Backup the Minecraft server (gierki)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${script}/bin/backup-minecraft-server-gierki";
        };
      };

    systemd.timers.backup-minecraft-gierki = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1h";
        OnUnitActiveSec = "1h";
        Unit = "backup-minecraft-gierki.service";
      };
    };

    systemd.services.backup-minecraft-luczkiewy =
      let
        script = pkgs.writeShellScriptBin "backup-minecraft-server-luczkiewy" "
          #!/usr/bin/env bash

          set -euo pipefail
          set -x

          ${pkgs.rcon}/bin/rcon -H localhost -p 25576 -P rcon <<EOS
            say [§4WARNING§r] starting server backup
            save-off
            save-all
EOS
          ${pkgs.gnutar}/bin/tar -cf /tmp/luczkiewy.tar /srv/minecraft/luczkiewy/
          ${pkgs.rcon}/bin/rcon -H localhost -p 25576 -P rcon <<EOS
            save-on
            say [§bNOTICE§r] server backup finished
EOS
          ${pkgs.rclone}/bin/rclone --config=${config.age.secrets.caligari-minecraft-rclone-config.path} --verbose copy /tmp/luczkiewy.tar b2:ramona-minecraft-backups/
          rm /tmp/luczkiewy.tar
        ";
      in
      {
        after = [ "network.target" ];
        description = "Backup the Minecraft server (luczkiewy)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${script}/bin/backup-minecraft-server-luczkiewy";
        };
      };

    systemd.timers.backup-minecraft-luczkiewy = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1h";
        OnUnitActiveSec = "1h";
        Unit = "backup-minecraft-luczkiewy.service";
      };
    };

    networking.firewall.allowedTCPPorts = [
      43000 # gierki
      43001 # luczkiewy
    ];
  };
}
