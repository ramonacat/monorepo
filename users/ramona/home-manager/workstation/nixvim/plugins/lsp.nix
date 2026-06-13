{ pkgs, ... }: {
  config = {
    programs.nixvim.plugins.lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        basedpyright.enable = true;
        bashls.enable = true;
        buf_ls.enable = true;
        csharp_ls.enable = true;
        jdtls.enable = true;
        lua_ls.enable = true;
        nil_ls.enable = true;
        nixd.enable = true;
        nushell.enable = true;
        pest_ls.enable = true;
        phpactor.enable = true;
        terraformls.enable = true;
        ts_ls.enable = true;
        twiggy_language_server = {
          enable = true;
          package = pkgs.writeShellScriptBin "twiggy-language-server" ''
            ${pkgs.nodejs_24}/bin/npx twiggy-language-server "$@"
          '';
        };
        yamlls = {
          enable = true;
          schemas = {
            # path for fluxcd
            "kubernetes" = "/clusters/**";
          };
        };
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
          mode = [
            "v"
            "n"
          ];
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
