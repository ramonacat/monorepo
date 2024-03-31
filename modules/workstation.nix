{pkgs, ...}: {
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

    services.pipewire.extraConfig.pipewire = {
      "99-roc-sink" = {
        "context.modules" = [
          {
            name = "libpipewire-module-roc-sink";
            args = {
              "fec.code" = "rs8m";
              "remote.ip" = "10.69.10.29";
              "remote.source.port" = 10001;
              "remote.repair.port" = 10002;
              "remote.control.port" = 10003;
              "sink.name" = "moonfall";
              "sink.props" = {
                "node.name" = "moonfall-sink";
              };
            };
          }
        ];
      };
    };
    networking.firewall.allowedUDPPorts = [10001 10002 10003];
    networking.firewall.allowedTCPPorts = [10001 10002 10003];
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
