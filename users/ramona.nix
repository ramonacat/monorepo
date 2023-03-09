{ lib, modulesPath, pkgs, ... }:
{
  config = {
    home-manager.users.ramona = {
      nixpkgs.config.allowUnfree = true;
      home.username = "ramona";
      home.homeDirectory = "/home/ramona";
      home.stateVersion = "22.11";
      home.packages = with pkgs; [ minikube kubectl nix-index nil pulseaudio ];

      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        pinentryFlavor = "tty";
      };

      programs.direnv.enable = true;
      programs.zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "agnoster";
          plugins = [ "git" "docker" ];
        };
      };

      programs.git = {
        enable = true;
        userName = "Ramona Łuczkiewicz";
        userEmail = "ja@agares.info";
        signing = {
          signByDefault = true;
          key = "682AC8D9096D4E08";
        };
        aliases = {
          st = "status -sb";
        };
        extraConfig = {
          push = {
            autoSetupRemote = true;
          };
        };
      };
    };

    users.users.ramona = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPG2s9Ym8R4qfO5QG74hADHZXuUEIlAYtcLtT38Opw1l ramona@hallewell"
      ];
      shell = pkgs.zsh;
    };
  };
}
