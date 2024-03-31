{
  lib,
  pkgs,
  config,
  ...
}: {
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
    home-manager.users.ramona = {
      home.packages = with pkgs; [
        wl-clipboard
        wtype
      ];
      services = {
        network-manager-applet.enable = true;
        blueman-applet.enable = config.services.blueman.enable;
        swayidle = {
          enable = true;
          timeouts = [
            {
              timeout = 540;
              command = "${pkgs.sway}/bin/swaymsg \"output * dpms off\"";
              resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\"";
            }
            {
              timeout = 600;
              command = "${pkgs.systemd}/bin/systemctl suspend";
              resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\"";
            }
          ];
        };
        udiskie.enable = true;
      };

      programs.waybar = {
        enable = true;
        systemd.enable = true;
        style = ''
          * { font-size: 24px; }

          window#waybar {
            background-color: transparent;
          }

          #workspaces button:hover {
              box-shadow: none; /* Remove predefined box-shadow */
              text-shadow: none; /* Remove predefined text-shadow */
              background: none; /* Remove predefined background color (white) */
              transition: none; /* Disable predefined animations */
          }

          #clock,
          #battery,
          #cpu,
          #memory,
          #disk,
          #temperature,
          #backlight,
          #network,
          #pulseaudio,
          #wireplumber,
          #custom-media,
          #tray,
          #mode,
          #idle_inhibitor,
          #scratchpad,
          #mpd,
          #upower,
          #language {
              padding: 3px 10px;
              margin: 3px 10px;

              border: 1px solid #070c17;
              border-radius: 15px;
              background-color: #20242e;
          }

          #workspaces button {
              color: white;
          }

          #workspaces button.focused {
              color: #ff1885;
          }
        '';

        settings = [
          {
            height = 30;
            layer = "top";
            position = "top";
            tray = {
              spacing = 10;
            };
            modules-left = ["sway/workspaces" "sway/mode"];
            modules-right =
              (
                if config.services.upower.enable
                then ["upower"]
                else []
              )
              ++ [
                "sway/language"
                "pulseaudio"
                "cpu"
                "clock"
                "tray"
              ];
            "sway/language" = {
              format = "{flag}";
            };
            pulseaudio = {
              format = "{icon}  {volume}%";
              format-bluetooth = "{icon}  {volume}%";
              format-muted = "🔇";
              "format-icons" = {
                "headphone" = "";
                "hands-free" = "";
                "headset" = "";
                "phone" = "";
                "portable" = "";
                "car" = "";
                "default" = ["🔊"];
              };
            };
            cpu = {
              format = "🏋 {load}";
            };
            clock = {
              format = "🕛 {:%Y-%m-%d %H:%M}";
            };
            tray = {
              icon-size = 24;
            };
          }
        ];
      };

      wayland.windowManager.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
        systemd.enable = true;
        config = {
          terminal = "alacritty";
          modifier = "Mod4";
          keybindings = let
            inherit (config.home-manager.users.ramona.wayland.windowManager.sway.config) modifier;
          in
            lib.mkOptionDefault {
              "${modifier}+d" = "exec ${pkgs.fuzzel}/bin/fuzzel";
              "${modifier}+e" = "exec BEMOJI_PICKER_CMD='${pkgs.fuzzel}/bin/fuzzel --dmenu' ${pkgs.bemoji}/bin/bemoji -t";
            };
          bars = [];
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
        '';
      };
    };
  };
}
