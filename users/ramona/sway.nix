{ barPackage }:
{ lib, modulesPath, pkgs, config, ... }:
{
  # colors: https://coolors.co/ff1885-19323c-9da2ab-f3de8a-988f2a
  config = {
    xdg.portal = {
      enable = true;
      wlr = {
        enable = true;
        settings = {
          screencast = {
            chooser_type = "simple";
            chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -ro";
          };
        };
      };
      config.common.default = "wlr";
    };
    home-manager.users.ramona =
      {
        home.packages = with pkgs; [
          wl-clipboard
          wtype
        ];
        services.network-manager-applet.enable = true;
        services.blueman-applet.enable = config.services.blueman.enable;
        services.swayidle = {
          enable = true;
          timeouts = [
            { timeout = 540; command = "${pkgs.sway}/bin/swaymsg \"output * dpms off\""; resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\""; }
            { timeout = 600; command = "${pkgs.systemd}/bin/systemctl suspend"; resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\""; }
          ];
        };

        services.udiskie.enable = true;

        wayland.windowManager.sway = {
          enable = true;
          wrapperFeatures.gtk = true;
          systemd.enable = true;
          config = {
            terminal = "alacritty";
            modifier = "Mod4";
            keybindings =
              let
                modifier = config.home-manager.users.ramona.wayland.windowManager.sway.config.modifier;
              in
              lib.mkOptionDefault {
                "${modifier}+d" = "exec ${pkgs.fuzzel}/bin/fuzzel";
                "${modifier}+e" = "exec BEMOJI_PICKER_CMD='${pkgs.fuzzel}/bin/fuzzel --dmenu' ${pkgs.bemoji}/bin/bemoji -t";
              };
            bars = [
              {
                position = "top";
                statusCommand = "${barPackage}/bin/bar";
                fonts = {
                  names = [ "Noto Sans" "Iosevka" ];
                  size = 13.0;
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
            bindsym Print exec '${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy'

            exec systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
            exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
          '';
        };
      };
  };
}
