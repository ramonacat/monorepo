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

    environment.etc."pipewire/pipewire.conf.d/scarlett.conf".source = ./scarlett.pipewire.conf;
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
