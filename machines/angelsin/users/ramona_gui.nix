{pkgs, ...}: {
  config = {
    home-manager.users.ramona = {
      systemd.user.services.virtual-monitor = let
        start_vnc = pkgs.writeScript "start_vnc" ''
          #!${pkgs.nushell}/bin/nu

          let headlessOutput = (${pkgs.sway}/bin/swaymsg -t get_outputs | from json | filter {|x| $x.name starts-with 'HEADLESS-' } | last | get name);
          ${pkgs.sway}/bin/swaymsg output $headlessOutput mode 1920x1280 pos "1128 0" scale 1.5
          ${pkgs.wayvnc}/bin/wayvnc $"--output=($headlessOutput)" -f 60 -g -r -Linfo 0.0.0.0 5900
        '';
        destroy_output = pkgs.writeScript "start_vnc" ''
          #!${pkgs.nushell}/bin/nu

          let headlessOutput = (${pkgs.sway}/bin/swaymsg -t get_outputs | from json | filter {|x| $x.name starts-with 'HEADLESS-' } | last | get name);
          ${pkgs.sway}/bin/swaymsg output $headlessOutput unplug
        '';
      in {
        Unit.Description = "This starts a virtual monitor over VNC";
        Service = {
          Type = "simple";
          ExecStartPre = "${pkgs.sway}/bin/swaymsg create_output HEADLESS-1";
          ExecStart = "${start_vnc}";
          ExecStop = "${destroy_output}";
        };
      };

      services.kanshi = {
        enable = true;
        profiles.standalone = {
          outputs = [
            {
              criteria = "BOE 0x0BCA Unknown";
              status = "enable";
              position = "0,0";
            }
          ];
          exec = "${pkgs.systemd}/bin/systemctl --user stop lan-mouse";
        };
        profiles.desk = {
          outputs = [
            {
              criteria = "BOE 0x0BCA Unknown";
              status = "disable";
            }
            {
              criteria = "LG Electronics LG ULTRAFINE 302MAUAEEJ14";
              status = "enable";
              position = "1920,0";
              scale = 1.5;
            }
            {
              criteria = "Dell Inc. DELL U2415 XKV0P9C334FS";
              status = "enable";
              position = "4480,0";
              scale = 1.0;
            }
            {
              criteria = "Dell Inc. DELL U2415 7MT0186418CU";
              status = "enable";
              position = "0,0";
              scale = 1.0;
            }
          ];
          exec = "${pkgs.systemd}/bin/systemctl --user restart lan-mouse";
        };
      };

      wayland.windowManager.sway = {
        config = {
          input = {
            "type:touchpad" = {
              "dwt" = "enabled";
              "tap" = "enabled";
              "middle_emulation" = "enabled";
            };
          };
          output = {
            "BOE 0x0BCA Unknown" = {
              "pos" = "0,0";
            };

            "Dell Inc. DELL U2415 7MT0186418CU" = {
              pos = "0 0";
              bg = "/dev/null fill #000000";
            };
            "LG Electronics LG ULTRAFINE 302MAUAEEJ14" = {
              scale = "1.5";
              pos = "1920 0";
              bg = "/dev/null fill #000000";
            };
            "Dell Inc. DELL U2415 XKV0P9C334FS" = {
              pos = "4480 0";
              bg = "/dev/null fill #000000";
            };
          };
        };
      };
    };
  };
}
