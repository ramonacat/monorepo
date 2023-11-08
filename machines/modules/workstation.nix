{ config, pkgs, lib, modulesPath, ... }:
{
  config = {
    virtualisation.docker.enable = true;

    security.rtkit.enable = true;
    security.sudo.wheelNeedsPassword = false;

    services.udisks2.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = {
        enable = true;
      };
    };

    programs.dconf.enable = true;
    programs.nix-ld.enable = true;

    fileSystems."/mnt/nas" = {
      device = "hallewell:/mnt/nas3/data";
      fsType = "nfs";
      options = [ "x-systemd.after=tailscaled.service" ];
    };

    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        iosevka
        noto-fonts
        noto-fonts-emoji
        lato
      ];

      fontconfig = {
        hinting.autohint = true;
        antialias = true;

        defaultFonts = {
          serif = [ "Noto Serif" "Noto Color Emoji" ];
          sansSerif = [ "Lato" "Noto Sans" "Noto Color Emoji" ];
          monospace = [ "Iosevka" "Noto Color Emoji" ];
        };
      };
    };
  };
}
