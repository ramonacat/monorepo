{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  home = {
    homeDirectory = "/home/ramona";
    username = "ramona";
    stateVersion = "21.05";
    packages = with pkgs; [
      agenix
      atop
      jq
      pulseaudio
      ripgrep
      unzip
      yt-dlp
    ];
  };
  services.gpg-agent.pinentryPackage = lib.mkDefault pkgs.pinentry-curses;

  programs = {
    gpg = {
      enable = true;
      publicKeys = [
        {
          source = ../keys/ramona.pgp;
          trust = "ultimate";
        }
        {
          source = ../keys/ramona2.pgp;
          trust = "ultimate";
        }
      ];
      mutableTrust = false;
      mutableKeys = true;
    };

    tmux = {
      enable = true;
      clock24 = true;
      newSession = true;
      plugins = with pkgs.tmuxPlugins; [
        sensible
      ];
    };
    home-manager = {
      enable = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = ["682AC8D9096D4E08" "E9C995FE5B1BCC62"];
  };

  programs.direnv.enable = true;

  programs = {
    nushell = {
      enable = true;
      configFile.source = ../shell.nu;
    };
    starship = {
      enable = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Ramona Łuczkiewicz";
    userEmail = "ja@agares.info";
    signing = {
      signByDefault = true;
      key = "E9C995FE5B1BCC62";
    };
    aliases = {
      st = "status -sb";
      cleanbr = "! git branch -d `git branch --merged | grep -v '^*\\|main\\|master\\|staging\\|devel'`";
    };
    extraConfig = {
      push = {
        autoSetupRemote = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      auto-save-nvim
      cmp-git
      cmp-nvim-lsp
      cmp-vsnip
      kanagawa-nvim
      lush-nvim
      neo-tree-nvim
      nvim-lspconfig
      telescope-nvim
      vim-vsnip
      which-key-nvim

      nvim-treesitter
      nvim-treesitter-parsers.terraform
      nvim-treesitter-parsers.php
      nvim-treesitter-parsers.rust
      nvim-treesitter-parsers.nix
      nvim-treesitter-parsers.lua
    ];
    extraLuaConfig = lib.readFile ./../neovim/extraConfig.lua;
  };
}
