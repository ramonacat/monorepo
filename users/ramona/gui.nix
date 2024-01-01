{ nix-vscode-extensions }:
{ lib, modulesPath, pkgs, ... }:
{
  # colors: https://coolors.co/ff1885-19323c-9da2ab-f3de8a-988f2a
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
              background = "#282828";
              foreground = "#ebdbb2";
            };
            normal = {
              black = "#282828";
              red = "#cc241d";
              green = "#98971a";
              yellow = "#d79921";
              blue = "#458588";
              magenta = "#b16286";
              cyan = "#689d6a";
              white = "#a89984";
            };
            bright = {
              black = "#928374";
              red = "#fb4934";
              green = "#b8bb26";
              yellow = "#fabd2f";
              blue = "#83a598";
              magenta = "#d3869b";
              cyan = "#8ec07c";
              white = "#ebdbb2";
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

      home.file.".moc/config".text = ''
        Theme = nightly_theme
      '';
    };
  };
}
