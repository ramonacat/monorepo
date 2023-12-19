{ nix-vscode-extensions }:
{ lib, modulesPath, pkgs, ... }:
{
  # colors: https://coolors.co/ff1885-19323c-9da2ab-f3de8a-988f2a
  config = {
    home-manager.users.ramona = {
      programs.firefox.enable = true;
      programs.alacritty.enable = true;

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
        ];
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
