{ barPackage }:
{ lib, modulesPath, pkgs, ... }:
{
  # colors: https://coolors.co/ff1885-19323c-9da2ab-f3de8a-988f2a
  config = {
    home-manager.users.ramona = {
      services.swayidle = {
        enable = true;
        timeouts = [
          { timeout = 540; command = "${pkgs.sway}/bin/swaymsg \"output * dpms off\""; resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\""; }
          { timeout = 600; command = "${pkgs.systemd}/bin/systemctl suspend"; }
        ];
      };

      services.udiskie.enable = true;

      wayland.windowManager.sway = {
        enable = true;
        config = {
          terminal = "alacritty";
          modifier = "Mod4";
          bars = [
            {
              position = "top";
              statusCommand = "${barPackage}/bin/bar";
              fonts = {
                names = [ "Noto Sans" "Iosevka" ];
                size = 11.0;
              };
              colors = {
                activeWorkspace = {
                  background = "#19323C";
                  border = "#988F2A";
                  text = "#9DA2AB";
                };
                focusedWorkspace = {
                  background = "#19323C";
                  border = "#988F2A";
                  text = "#FF1885";
                };
              };
            }
          ];
          colors = {
            focused = {
              background = "#19323C";
              border = "#00000000";
              text = "#9DA2AB";
              indicator = "#988F2A";
              childBorder = "#00000000";
            };
          };
        };
        extraConfig = ''
          input * {
            xkb_layout "pl,de"
            xkb_options "grp:win_space_toggle"
          }
          bindsym Mod4+Tab workspace next_on_output
          bindsym Mod4+Shift+Tab workspace prev_on_output
          bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +5%'
          bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -5%'
          bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'
          bindsym XF86MonBrightnessUp exec sudo light -A 10
          bindsym XF86MonBrightnessDown exec sudo light -U 10
        '';
      };
    };
  };
}
