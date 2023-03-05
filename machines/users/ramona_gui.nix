{ lib, modulesPath, pkgs, ... }:
{
  config = {
    home-manager.users.ramona = {
      programs.firefox.enable = true;
      programs.alacritty.enable = true;

      home.packages = with pkgs; [ iosevka keepassxc discord virt-manager pavucontrol ];

      wayland.windowManager.sway = {
        enable = true;
        config = {
          terminal = "alacritty";
          modifier = "Mod4";
          output = {
            "Dell Inc. DELL U2720Q JKPQT83" = {
              scale = "2";
              pos = "1920 0";
              mode = "3840x2160@60Hz";
            };
            "Dell Inc. DELL U2415 7MT0186418CU" = { pos = "0 0"; };
            "Dell Inc. DELL U2415 XKV0P9C334FS" = { pos = "3840 0"; };
          };
        };
        extraConfig = "input * xkb_layout pl";
      };
    };

    users.users.ramona = {
      extraGroups = [ "libvirtd" ];
    };
  };
}
