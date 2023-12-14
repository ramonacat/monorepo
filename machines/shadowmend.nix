{ config, pkgs, lib, ... }:
{
  config = {
    services.logind.lidSwitch = "ignore";

    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [ docker-compose ];
  };
}
