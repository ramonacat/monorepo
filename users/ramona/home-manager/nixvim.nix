_: {
  imports = [
    ./nixvim/colorscheme.nix
    ./nixvim/diagnostics.nix
    ./nixvim/options.nix
    ./nixvim/plugins/auto-save-nvim.nix
    ./nixvim/plugins/blink-cmp.nix
    ./nixvim/plugins/blink-compat.nix
    ./nixvim/plugins/crates.nix
    ./nixvim/plugins/friendly-snippets.nix
    ./nixvim/plugins/lsp.nix
    ./nixvim/plugins/mini.nix
    ./nixvim/plugins/neo-tree.nix
    ./nixvim/plugins/rainbow-delimiters.nix
    ./nixvim/plugins/telescope.nix
    ./nixvim/plugins/treesitter-context.nix
    ./nixvim/plugins/treesitter.nix
  ];
  config = {
    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
    home.sessionVariables.EDITOR = "vim";
  };
}
