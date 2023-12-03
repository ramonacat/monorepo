{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "shadowmend";
    networking.enableIPv6 = false;

    networking.useDHCP = lib.mkForce false;
    networking.interfaces.enp0s20u1.useDHCP = lib.mkForce true;
    networking.interfaces.enp7s0.useDHCP = lib.mkForce true;
  };
}
