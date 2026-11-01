{ pkgs, ... }: {
  config = {
    programs.helix = {
      enable = true;
      extraPackages = with pkgs; [
        bash-language-server
        golangci-lint
        golangci-lint-langserver
        gopls
        gotools

        hongdown
        marksman

        nil
        nixd
        nixpkgs-fmt

        prettier
        typescript-language-server

        sql-formatter

        ruff
        (python3.withPackages (
          p:
          (with p; [
            python-lsp-ruff
            python-lsp-server
          ])
        ))

        rust-analyzer
        taplo
        terraform-ls
        typescript
        vscode-langservers-extracted
        yaml-language-server
      ];
      languages = {
        language-server = {
          rust-analyzer.config.check = {
            command = "clippy";
          };

          yaml-language-server.config.yaml.schemas = {
            kubernetes = "kubernetes/**/*.yaml";
          };
          typescript-language-server.config.tsserver = {
            path = "${pkgs.typescript}/lib/node_modules/typescript/lib/tsserver.js";
          };
        };
        language = [
          {
            name = "css";
            language-servers = [ "vscode-css-language-server" ];
            auto-format = true;
          }
          {
            name = "go";
            language-servers = [
              "gopls"
              "golangci-lint-lsp"
            ];
            formatter = {
              command = "goimports";
            };
            auto-format = true;
          }
          {
            name = "html";
            language-servers = [
              "vscode-html-language-server"
              "tailwindcss-ls"
            ];
            formatter = {
              command = "prettier";
              args = [
                "--stdin-filepath"
                "%{buffer_name}"
              ];
            };
            auto-format = true;
          }
          {
            name = "javascript";
            language-servers = [
              { name = "typescript-language-server"; }

            ];
            auto-format = true;
          }
          {
            name = "json";
            language-servers = [
              { name = "vscode-json-language-server"; }
            ];
            auto-format = true;
          }
          {
            name = "jsx";
            language-servers = [
              { name = "typescript-language-server"; }

            ];
            auto-format = true;
          }
          {
            name = "markdown";
            language-servers = [ "marksman" ];
            formatter = {
              command = "hongdown";
              args = [
                "--line-width=120"
                "--stdin"
              ];
            };
            auto-format = true;
          }
          {
            name = "nix";
            formatter = {
              command = "nixpkgs-fmt";
            };
            auto-format = true;
          }
          {
            name = "python";
            language-servers = [ "pylsp" ];
            formatter = {
              command = "sh";
              args = [
                "-c"
                "ruff check --select I --fix - | ruff format --line-length 88 -"
              ];
            };
            auto-format = true;
          }
          {
            name = "rust";
            language-servers = [ "rust-analyzer" ];
            auto-format = true;
          }
          {
            name = "sql";
            formatter = {
              command = "sql-formatter";
              args = [
                "-l"
                "postgresql"
                "-c"
                "{\"keywordCase\": \"upper\", \"dataTypeCase\": \"upper\", \"functionCase\": \"upper\", \"expressionWidth\": 100, \"tabWidth\": 4}"
              ];
            };
            auto-format = true;
          }
          {
            name = "toml";
            language-servers = [ "taplo" ];
            formatter = {
              command = "taplo";
              args = [
                "fmt"
                "-o"
                "column_width=120"
                "-"
              ];
            };
            auto-format = true;
          }
          {
            name = "tsx";
            language-servers = [
              { name = "typescript-language-server"; }
            ];
            auto-format = true;
          }
          {
            name = "typescript";
            language-servers = [
              { name = "typescript-language-server"; }

            ];
            auto-format = true;
          }
          {
            name = "yaml";
            language-servers = [ "yaml-language-server" ];
            formatter = {
              command = "prettier";
              args = [
                "--stdin-filepath"
                "%{buffer_name}"
              ];
            };
            auto-format = true;
          }
        ];
      };
      settings = {
        theme = "kanagawa-dragon";
        keys = {
          normal = {
            "g" = {
              "d" = [
                "hsplit"
                "jump_view_up"
                "goto_definition"
              ];
            };
          };
        };
        editor = {
          line-number = "relative";
          auto-save = {
            focus-lost = true;
            after-delay = {
              enable = true;
              timeout = 100;
            };
          };
          indent-guides = {
            render = true;
          };
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
        };
      };
    };
  };
}
