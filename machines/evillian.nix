{ config, pkgs, lib, ... }:
{
  config = {
    services.xserver.enable = true;
    services.xserver.displayManager.sddm = {
      enable = true;
    };
  };
}
