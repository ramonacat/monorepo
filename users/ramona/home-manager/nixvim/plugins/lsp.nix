_: {
  config = {
    programs.nixvim.plugins.lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        nixd.enable = true;
        rust_analyzer = {
          enable = true;
          installRustc = false;
          installCargo = false;
        };
        lua_ls.enable = true;
        nil_ls.enable = true;
        terraformls.enable = true;
        csharp_ls.enable = true;
        nushell.enable = true;
        jdtls.enable = true;
        phpactor.enable = true;
        ts_ls.enable = true;
        basedpyright.enable = true;
        pest_ls.enable = true;
      };

      keymaps.lspBuf = {
        gD = "declaration";
        gd = "definition";
        K = "hover";
        gi = "implementation";
        "<C-k>" = "signature_help";
        "<leader>D" = "type_definition";
        "<leader>rn" = "rename";
        "<leader>ca" = {
          action = "code_action";
          mode = ["v" "n"];
        };
        gr = "references";
      };
      keymaps.extra = [
        {
          key = "gsd";
          action = ":belowright split | lua vim.lsp.buf.definition()<CR>";
        }
        {
          key = "gSd";
          action = ":vertical split | lua vim.lsp.buf.definition()<CR>";
        }
      ];
    };
  };
}
