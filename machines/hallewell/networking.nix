{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "hallewell";

    networking.useDHCP = lib.mkForce false;
    networking.interfaces.eno1.useDHCP = lib.mkForce true;
  };
}
