_: {
  config = {
    programs.nixvim.lsp = {
      inlayHints.enable = true;
      servers = {
        nixd.enable = true;
        rust_analyer.enable = true;
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

      keymaps = [
        {
          key = "gD";
          lspBufAction = "declaration";
        }
        {
          key = "gd";
          lspBufAction = "definition";
        }
        {
          key = "gsd";
          action = ":belowright split | lua vim.lsp.buf.definition()<CR>";
        }
        {
          key = "K";
          lspBufAction = "hover";
        }
        {
          key = "gi";
          lspBufAction = "implementation";
        }
        {
          key = "<C-k>";
          lspBufAction = "signature_help";
        }
        {
          key = "<leader>D";
          lspBufAction = "type_definition";
        }
        {
          key = "<leader>rn";
          lspBufAction = "rename";
        }
        {
          key = "<leader>ca";
          lspBufAction = "code_action";
          mode = ["n" "v"];
        }
        {
          key = "gr";
          lspBufAction = "references";
        }
      ];
    };
  };
}
