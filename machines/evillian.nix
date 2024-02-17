{ config, pkgs, lib, ... }:
{
  config = {
    services.xserver = {
      enable = true;
      xkb.layout = "pl,de";
    };
    services.xserver.displayManager = {
      lightdm = {
        enable = true;
        greeters = {
          gtk = {
            enable = true;
          };
        };
      };
      defaultSession = "sway";
    };

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
  };
}
