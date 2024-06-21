{pkgs, ...}: {
  imports = [
    ./installed.nix
  ];
  # colors: https://coolors.co/ff1885-19323c-9da2ab-f3de8a-988f2a
  config = {
    # LANMouse
    networking.firewall.allowedUDPPorts = [4242];

    # pipewire over network
    networking.firewall.allowedTCPPorts = [4656];

    home-manager.users.ramona = {
      services.gpg-agent.pinentryPackage = pkgs.pinentry-qt;

      home = {
        packages = with pkgs; [
          dconf
          discord
          element-desktop
          flac
          grip
          hunspell
          hunspellDicts.de_DE
          hunspellDicts.en_US
          hunspellDicts.pl_PL
          keepassxc
          krita
          light
          loupe
          moc
          obs-studio
          obsidian
          pamixer
          pavucontrol
          playerctl
          ramona.lan-mouse
          spotify
          virt-manager
          vlc
          xdg-utils

          factorio
          prismlauncher
        ];

        pointerCursor = {
          name = "Adwaita";
          package = pkgs.gnome.adwaita-icon-theme;
          size = 36;
          x11 = {
            enable = true;
            defaultCursor = "Adwaita";
          };
        };
      };
      programs = {
        firefox.enable = true;
        alacritty = {
          enable = true;
          settings = {
            font = {
              size = 16;
            };
            window.opacity = 0.8;
            import = [
              pkgs.alacritty-theme.kanagawa_dragon
            ];
          };
        };
      };

      gtk = {
        enable = true;
        theme = {
          package = pkgs.dracula-theme;
          name = "Dracula";
        };
      };

      qt = {
        enable = true;
        style.name = "Dracula";
        platformTheme = "gtk3";
      };

      home.file.".moc/config".text = ''
        Theme = nightly_theme
      '';
    };
  };
}
