{ config, pkgs, lib, ... }:
{
  config = {
    fileSystems."/mnt/nas" =
      {
        device = "10.69.10.139:/mnt/data0/data";
        fsType = "nfs";
      };

    services.tailscale.enable = true;
    services.logind.lidSwitch = "ignore";

    virtualisation.docker.enable = true;
  };
}
