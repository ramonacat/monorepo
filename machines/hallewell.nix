{ config, pkgs, lib, ... }:
{
  config = {
    powerManagement.powertop.enable = true;
    services.syncthing = {
      user = lib.mkForce "nas";
      dataDir = lib.mkForce "/mnt/nas3/syncthing/data/";
      configDir = lib.mkForce "/mnt/nas3/syncthing/config/";

      settings.folders.shared.path = lib.mkForce "/mnt/nas3/data/shared/";
    };
  };
}
