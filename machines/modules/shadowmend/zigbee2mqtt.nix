{ config, pkgs, lib, ... }:
{
  config = {
    services.zigbee2mqtt = {
      enable = true;

      settings = {
        frontend = {
          port = 8098;
        };
        serial = {
          port = "/dev/ttyACM0";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 8098 ];
  };
}
