{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "hallewell";
    networking.interfaces.br0.useDHCP = true;

    networking.bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };
  };
}
