{ config, pkgs, lib, ... }:
{
  config = {
    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;

      servers = {
        gierki = {
          enable = true;
          whitelist = {
            Agares2 = "2535f2de-9174-4bc5-8bdf-233649bc0449";
          };
          serverProperties = {
            server-port = 43000;
            white-list = true;
          };
          package = pkgs.minecraftServers.vanilla-1_20_4;
        };
      };
    };
  };
}
