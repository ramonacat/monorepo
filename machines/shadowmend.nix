{ config, pkgs, lib, ... }:
{
  config = {
    fileSystems."/mnt/nas" =
      {
        device = "10.69.10.5:/mnt/nas3/data";
        fsType = "nfs";
      };

    services.logind.lidSwitch = "ignore";

    virtualisation.docker.enable = true;
    environment.systemPackages = with pkgs; [ docker-compose ];
  };
}
