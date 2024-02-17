{ config, pkgs, lib, ... }:
{
  config = {
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "0.0.0.0" ];
        };
      };
    };
    networking.firewall.allowedUDPPorts = [ 53 ];
  };
}
