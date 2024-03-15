{
  agenix,
  ratPackage,
}: {
  lib,
  modulesPath,
  pkgs,
  config,
  ...
}: {
  config = {
    home-manager.users.ramona = let
      homeDirectory = "/home/ramona";
    in {
      imports = [
        (import ../modules/home-manager/rat.nix {inherit ratPackage;})
      ];
      nixpkgs.config.allowUnfree = true;
      home.username = "ramona";
      home.homeDirectory = homeDirectory;
      home.stateVersion = "22.11";
      home.packages = with pkgs; [
        pulseaudio
        unzip
        yt-dlp
        agenix.packages.x86_64-linux.default
        jq
        atop
        ripgrep
        nixd
        ratPackage
      ];

      programs.rat = {
        enable = lib.attrsets.hasAttrByPath ["services" "syncthing" "settings" "folders" "shared"] config;
        dataFile = homeDirectory + "/shared/todos.json";
      };

      programs.gpg = {
        enable = true;
        publicKeys = [
          {
            source = ./ramona.pgp;
            trust = "ultimate";
          }
          {
            source = ./ramona2.pgp;
            trust = "ultimate";
          }
        ];
        mutableTrust = false;
        mutableKeys = false;
      };

      programs.tmux = {
        enable = true;
        clock24 = true;
        newSession = true;
        plugins = with pkgs.tmuxPlugins; [
          sensible
        ];
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
          # The config.nu can be anywhere you want if you like to edit your Nushell with Nu
          configFile.source = ./ramona.nu;
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
        extraLuaConfig = lib.readFile ./ramona/neovim/extraConfig.lua;
      };
    };

    users.users.ramona = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "docker" "cdrom" "audio" "adbusers"];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCatH7XWmY6oZPSe3woP2swvJ4/stZrpaVWNg6FMcs87xEtCr/sIkj/rm41gD6F3k3Z6jhxqBKgZcr45aW07xlB//KfYs3kb0PYDsn3KrwCPBjHwRypuPvyagCUDAbD9wnhpEr9iHEbhW2yNEDC5E1c3ak/fNjewCZMpqo645gQ6siFAnwEnqTQR0lF3B/hdmAA/j+efQ3ghjiI6+O3uQ0o5coCNa4tCrq3yqsyA7eI0jhT1Ij8SE54ren3dwndq1JoGNg7DCtozl3fCgHVUrdWeW2kcB1A/Ta+jcmcB10Rv9ZevU2wYvZIEYXG1hSjM8Zrr7JwAcXkG/mb3lGnYnU49YxNqT4vwD0ZyY8d5M9Hvw065+y7Y45+/ScevmIGn/fn/9TbZHdPdSKM1UFMICUctT6VH6ShhEkbiQ38E3GnA1n3mnsOnxaBT5hVJxr13yLV8ULU/8not6SMU/3xP2rZj6JP7xtHJP/29Nd4N7gm6adz3wbS1aRJosVr3ZbA1qTaB/m4EBRTfNYtifUbdQkFbrnlNmVNb5ixhS1ZLZq4aRPmp6MH034sQ9HZSrtMMSO5B9TXHCb3zxexR6BBtIjZHBqwuu3krMWh9kOW3wNFWmEWdy5vLUcVVoXSaGqICQwG/HOKGNdzGumFDnPfvayVVCxu67s2b82oTtkbd+mjMQ== openpgp:0xCF7158EB" # nitrokey
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKK5e1b1wQLyZ0RByYmhlKj4Kksv4dvnwTowDPaGsq4D openpgp:0x7688871E" # nitrokey 3
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFwrLwnv2MBsa3Isr54AyFBBeFxMRF3U+lkdU5+ECv9 ramona@caligari" # caligari
      ];
      shell = pkgs.nushell;
    };
  };
}
