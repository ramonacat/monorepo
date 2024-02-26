{ config, pkgs, lib, modulesPath, ... }:
{
  config = {
    virtualisation.docker.enable = true;

    security.rtkit.enable = true;
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

    environment.etc."pipewire/pipewire.conf.d/roc-sink.conf".source = ./roc-sink.pipewire.conf;
    networking.firewall.allowedUDPPorts = [ 10001 10002 10003 ];
    networking.firewall.allowedTCPPorts = [ 10001 10002 10003 ];
    boot.plymouth = {
      enable = true;
      theme = "breeze";
    };

    programs.dconf.enable = true;
    programs.nix-ld.enable = true;

    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        iosevka
        noto-fonts
        noto-fonts-emoji
        lato
        (nerdfonts.override { fonts = [ "Iosevka" ]; })
      ];

      fontconfig = {
        hinting.autohint = true;
        antialias = true;

        defaultFonts = {
          serif = [ "Noto Serif" "Noto Color Emoji" ];
          sansSerif = [ "Lato" "Noto Sans" "Noto Color Emoji" ];
          monospace = [ "Iosevka Nerd Font" "Noto Color Emoji" ];
        };
      };
    };
  };
}
