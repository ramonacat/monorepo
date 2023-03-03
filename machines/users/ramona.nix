{ lib, modulesPath, pkgs, ... }:
  {
    config = {
      

      home-manager.users.ramona = {
        home.username = "ramona";
        home.homeDirectory = "/home/ramona";
        home.stateVersion = "22.11";
        home.packages = with pkgs; [minikube kubectl nix-index nil];

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
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDeaj+jUyPJVfT3UE7uYZo85AMLeeegBk+1Q/a4gwTq8NUxxIe/hzE6Zjlu2rwT4iJvwtO+/lD8p+7jIpjZuj9ki0plFHG7aCXD7I6gNLvxyWj+wH0Qedt+sxLWDndpjrjT3hvQXczUN3sPIWQO3ezvDqvgOT78YqQXmhis0aUcGiCoH50nTvjzh9qQCEBRXFYJYKPmyJIFqN6J0T7yPfyWigrbt1bSTXxqeQ8+HFueCoFVeZ3h5Wb0O0bdIrAM5mH3TtIcBc3tX2q0zkJwoYZT47mduvlyzIcWczX3B/kltD8Av3UvPLKwzU6OYSsGf5xUBqEHUK0QU7DBwnC7CD1F josey666@DESKTOP-V5VIUJD"
        ];
        shell = pkgs.zsh;
      };
    };
  }