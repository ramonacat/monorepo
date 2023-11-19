{ config, pkgs, lib, ... }:
{
  config = {
    networking.hostName = "ananas";
    networking.enableIPv6 = false;
  };
}
