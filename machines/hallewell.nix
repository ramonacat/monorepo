{ config, pkgs, lib, ... }:
{
  config = {
    powerManagement.powertop.enable = true;
    services.syncthing.settings.folders.shared.path = lib.mkForce "/mnt/nas3/data/shared/";
  };
}
