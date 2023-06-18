{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "shadowmend";

    networking.useDHCP = lib.mkForce false;
    networking.interfaces.enp0s29u1u2.useDHCP = lib.mkForce true;
    networking.interfaces.enp7s0.useDHCP = lib.mkForce true;
  };
}
