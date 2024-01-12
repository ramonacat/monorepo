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

    networking.firewall.allowedTCPPorts = [
      # For VNC 
      5900
    ];
  };
}
