{ config, pkgs, lib, ... }:
{
  config = {
    home-manager.users.ramona = {
      wayland.windowManager.sway = {
        config = {
          input = {
            "type:touchpad" = {
              "dwt" = "enabled";
              "tap" = "enabled";
              "middle_emulation" = "enabled";
            };
          };
        };
      };
    };
  };
}
