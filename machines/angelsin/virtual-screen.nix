{ config, pkgs, lib, ... }: {
  config = {
    networking.firewall.allowedTCPPorts = [
      # For VNC 
      5900
    ];
  };
}
