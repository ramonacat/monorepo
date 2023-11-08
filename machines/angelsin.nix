{ config, pkgs, lib, ... }:
{
  config = {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    services.power-profiles-daemon.enable = true;
    powerManagement.powertop.enable = true;
    services.upower.enable = true;

    security.polkit.enable = true;

    services.syncthing = {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      user = "ramona";

      dataDir = "/home/ramona/.syncthing-data";
      configDir = "/home/ramona/.config/syncthing";

      settings = {
        devices = {
          "phone" = { "id" = "VZK66I4-WTFCOWJ-B7LH6QV-FDQFTSH-FTBWTIH-UUDRUOR-SNIZBPS-AMRDBAU"; };
          "hallewell" = { "id" = "BKZEEQS-2VYH2DZ-FRANPJH-I4WOFMZ-DO3N7AJ-XSK7J3D-P57XCTW-S66ZEQY"; };
          "tablet" = { "id" = "RRUE6ZX-AXPN4HG-DUFIBV5-A4A3CTI-KQ3QO25-7WTBNWM-OUMDZUA-NLFBVQK"; };
          "moonfall" = { "id" = "Q4Q2BJN-FCJSVJO-UR7RWY3-INF4JR7-JNZMZX4-KR5WXTQ-JCNI3X5-IGBEEAL"; };
        };

        folders = {
          "shared" = {
            path = "/home/ramona/shared/";
            devices = [ "phone" "hallewell" "tablet" "moonfall" ];
          };
        };
      };
    };

    # For syncthing
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
