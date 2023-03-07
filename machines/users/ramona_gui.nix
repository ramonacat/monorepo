{ lib, modulesPath, pkgs, ... }:
{
  config = {
    home-manager.users.ramona = {
      programs.firefox.enable = true;
      programs.alacritty.enable = true;

      home.packages = with pkgs; [ iosevka keepassxc discord virt-manager pavucontrol looking-glass-client pamixer playerctl noto-fonts noto-fonts-emoji xdg-utils ];
      programs.vscode = {
        enable = true;
        package = pkgs.vscode.fhsWithPackages (ps: with ps; [ pkg-config ]);
        extensions = with pkgs.vscode-extensions; [
          timonwong.shellcheck
          tamasfe.even-better-toml
        ];
      };

      wayland.windowManager.sway = {
        enable = true;
        config = {
          terminal = "alacritty";
          modifier = "Mod4";
          output = {
            "Dell Inc. DELL U2720Q JKPQT83" = {
              scale = "1";
              pos = "1920 0";
              mode = "1920x1080";
            };
            "Dell Inc. DELL U2415 7MT0186418CU" = { pos = "0 0"; };
            "Dell Inc. DELL U2415 XKV0P9C334FS" = { pos = "3840 0"; };
          };
          bars = [
            {
              position = "top";
              statusCommand = "while ${./scripts/swaybar.sh}; do sleep 1; done";
              fonts = {
                names = [ "Noto Sans" "Iosevka" ];
                size = 11.0;
              };
            }
          ];
        };
        extraConfig = ''
          input * xkb_layout pl
          bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'
          bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'
          bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'
        '';
      };
    };

    users.users.ramona = {
      extraGroups = [ "libvirtd" ];
    };
  };
}
