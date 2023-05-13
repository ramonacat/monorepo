{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "moonfall";

    networking.useDHCP = lib.mkForce false;
    networking.interfaces.br0.useDHCP = lib.mkForce false;
    networking.interfaces.eno1.useDHCP = lib.mkForce false;

    networking.interfaces.br0.ipv4.addresses = [
      { address = "10.69.10.7"; prefixLength = 24; }
    ];

    networking.defaultGateway = "10.69.10.1";
    networking.nameservers = [ "8.8.8.8" ];

    networking.bridges = {
      "br0" = {
        interfaces = [ "eno1" ];
      };
    };
  };
}
