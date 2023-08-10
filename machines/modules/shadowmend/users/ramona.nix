{ config, pkgs, lib, ... }:
{
  config = {
    users.user.ramona.extraGroups = [ "docker" ];
  };
}
