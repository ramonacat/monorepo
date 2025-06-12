{
  pkgs,
  lib,
  ...
}: {
  home = {
    homeDirectory = "/home/ramona";
    username = "ramona";
    stateVersion = "21.05";
    packages = with pkgs; [
      agenix
      atop
      jq
      ripgrep
      unzip
      _1password-cli
      rustup
      irssi
    ];
  };
  services.gpg-agent.pinentry.package = lib.mkDefault pkgs.pinentry-curses;

  programs = {
    tmux = {
      enable = true;
      clock24 = true;
      newSession = true;
      mouse = true;
      keyMode = "vi";
      customPaneNavigationAndResize = true;
      prefix = "C-space";
      plugins = with pkgs.tmuxPlugins; [
        sensible
      ];
    };
    home-manager = {
      enable = true;
    };
  };

  programs.direnv.enable = true;

  programs = {
    bash = {
      enable = true;
    };
  };

  programs.git = {
    enable = true;
    userName = "Ramona Łuczkiewicz";
    userEmail = "ja@agares.info";
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
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      auto-save-nvim
      cmp-nvim-lsp
      cmp-vsnip
      kanagawa-nvim
      neo-tree-nvim
      nvim-cmp
      nvim-lspconfig
      nvim-treesitter-context
      nvim-treesitter.withAllGrammars
      pest-vim
      telescope-nvim
      vim-vsnip
    ];
    extraLuaConfig = lib.readFile ./../neovim/extraConfig.lua;
  };
}
