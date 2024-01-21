{ nix-vscode-extensions }:
{ lib, modulesPath, pkgs, ... }:
{
  # colors: https://coolors.co/ff1885-19323c-9da2ab-f3de8a-988f2a
  # terminal colors: https://github.com/mbadolato/iTerm2-Color-Schemes/blob/master/alacritty/Jellybeans.yml
  config = {
    home-manager.users.ramona = {
      programs.firefox.enable = true;
      programs.alacritty = {
        enable = true;
        settings = {
          font = {
            size = 16;
          };
          colors = {
            primary = {
              background = "#121212";
              foreground = "#dedede";
            };
            selection = {
              background = "#474e91";
              text = "#f4f4f4";
            };
            normal = {
              black = "#929292";
              blue = "#97bedc";
              cyan = "#00988e";
              green = "#94b979";
              magenta = "#e1c0fa";
              red = "#e27373";
              white = "#dedede";
              yellow = "#ffba7b";
            };
            bright = {
              black = "#bdbdbd";
              blue = "#b1d8f6";
              cyan = "#1ab2a8";
              green = "#bddeab";
              magenta = "#fbdaff";
              red = "#ffa1a1";
              white = "#ffffff";
              yellow = "#ffdca0";
            };
          };
        };
      };

      home.packages = with pkgs; [
        keepassxc
        discord
        virt-manager
        pavucontrol
        pamixer
        playerctl
        xdg-utils
        dconf
        moc
        grip
        flac
        spotify
        vlc
        hunspell
        hunspellDicts.de_DE
        hunspellDicts.en_US
        hunspellDicts.pl_PL
        obsidian
        light
        loupe
        obs-studio

        factorio
        prismlauncher
      ];

      home.pointerCursor = {
        name = "Adwaita";
        package = pkgs.gnome.adwaita-icon-theme;
        size = 36;
        x11 = {
          enable = true;
          defaultCursor = "Adwaita";
        };
      };

      programs.vscode = {
        enable = true;
        mutableExtensionsDir = false;
        extensions = with nix-vscode-extensions.extensions.x86_64-linux.vscode-marketplace; [
          panicbit.cargo
          devsense.composer-php-vscode
          ms-azuretools.vscode-docker
          tamasfe.even-better-toml
          github.vscode-github-actions
          ms-kubernetes-tools.vscode-kubernetes-tools
          bbenoist.nix
          jnoortheen.nix-ide
          ms-ossdata.vscode-postgresql
          arrterian.nix-env-selector
          rust-lang.rust-analyzer
          bbenoist.nix
          arrterian.nix-env-selector
          thenuprojectcontributors.vscode-nushell-lang
          hashicorp.terraform
        ];
        userSettings = {
          "workbench.colorTheme" = "Visual Studio Dark";
          "window.zoomLevel" = 1;
          "editor.fontFamily" = "'Iosevka', 'monospace', monospace";
          "files.autoSave" = "onFocusChange";
          "editor.cursorBlinking" = "smooth";
          "editor.fontLigatures" = true;
          "editor.mouseWheelZoom" = true;
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

      services.gpg-agent.pinentryFlavor = lib.mkForce "qt";

      home.file.".moc/config".text = ''
        Theme = nightly_theme
      '';
    };
  };
}
