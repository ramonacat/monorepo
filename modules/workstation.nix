{pkgs, ...}: {
  config = {
    virtualisation.docker.enable = true;

    security.rtkit.enable = true;
    services = {
      udisks2.enable = true;
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse = {
          enable = true;
        };
      };
    };
    boot.plymouth = {
      enable = true;
      theme = "breeze";
    };

    programs.dconf.enable = true;

    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        iosevka
        noto-fonts
        noto-fonts-emoji
        lato
        (nerdfonts.override {fonts = ["Iosevka"];})
      ];

      fontconfig = {
        hinting.autohint = true;
        antialias = true;

        defaultFonts = {
          serif = ["Noto Serif" "Noto Color Emoji"];
          sansSerif = ["Lato" "Noto Sans" "Noto Color Emoji"];
          monospace = ["Iosevka Nerd Font" "Noto Color Emoji"];
        };
      };
    };
  };
}
