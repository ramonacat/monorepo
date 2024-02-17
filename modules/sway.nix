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
    powerManagement.powertop.enable = true;
    services.upower.enable = true;

    environment.systemPackages =
      let
        # bash script to let dbus know about important env variables and
        # propagate them to relevent services run at the end of sway config
        # see
        # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
        # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts  
        # some user services to make sure they have the correct environment variables
        dbus-sway-environment = pkgs.writeTextFile {
          name = "dbus-sway-environment";
          destination = "/bin/dbus-sway-environment";
          executable = true;

          text = ''
            dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
            systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr swayidle
            systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr swayidle
          '';
        };
      in
      [ dbus-sway-environment ];
  };
}
