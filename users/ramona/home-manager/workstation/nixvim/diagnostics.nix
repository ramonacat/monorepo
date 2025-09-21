{config, ...}: {
  config = {
    programs.nixvim.keymaps = [
      {
        key = "[d";
        action = config.lib.nixvim.mkRaw "function() vim.diagnostic.jump({ count = -1 }) end";
      }
      {
        key = "]d";
        action = config.lib.nixvim.mkRaw "function() vim.diagnostic.jump({ count = 1 }) end";
      }
      {
        key = "<leader>q";
        action = config.lib.nixvim.mkRaw "vim.diagnostic.setloclist";
      }
    ];
  };
}
