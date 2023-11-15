{ config, pkgs, lib, ... }:
{
  config = {
    services.zigbee2mqtt = {
      enable = true;

      settings = {
        serial = {
          port = "/dev/ttyACM0";
        };
      };
    };
  };
}
