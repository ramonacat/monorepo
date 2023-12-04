{ config, pkgs, lib, ... }:
{
  config = {
    home-manager.users.ramona = {
      systemd.user.services.virtual-monitor =
        let
          start_vnc = pkgs.writeScript "start_vnc" ''
            #!${pkgs.nushell}/bin/nu

            let headlessOutput = (${pkgs.sway}/bin/swaymsg -t get_outputs | from json | filter {|x| $x.name starts-with 'HEADLESS-' } | last | get name);
            ${pkgs.sway}/bin/swaymsg output $headlessOutput mode 1920x1280 pos "1128 0" scale 1.5
            ${pkgs.wayvnc}/bin/wayvnc $"--output=($headlessOutput)" -f 60 -g -r -Linfo 10.69.254.1 5900
          '';
          destroy_output = pkgs.writeScript "start_vnc" ''
            #!${pkgs.nushell}/bin/nu

            let headlessOutput = (${pkgs.sway}/bin/swaymsg -t get_outputs | from json | filter {|x| $x.name starts-with 'HEADLESS-' } | last | get name);
            ${pkgs.sway}/bin/swaymsg output $headlessOutput unplug
          '';

        in
        {
          Unit.Description = "This starts a virtual monitor over VNC";
          Service = {
            Type = "simple";
            ExecStartPre = "${pkgs.sway}/bin/swaymsg create_output HEADLESS-1";
            ExecStart = "${start_vnc}";
            ExecStop = "${destroy_output}";
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
          };
        };
      };
    };
  };
}
