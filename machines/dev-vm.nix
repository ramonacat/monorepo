{ config, pkgs, lib, modulesPath, vscode-server, ...}:
  {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];
    
    config = {
      boot.initrd.availableKernelModules = [ "ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "xhci_pci" "sd_mod" "sr_mod" ];
      fileSystems."/" = {
        device = "/dev/disk/by-uuid/14907592-83ac-45be-8a89-a4be82838a3e";
        fsType = "ext4";
      };

      networking.useDHCP = lib.mkDefault true;

      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/sda";

      networking.hostName = "ramona-dev-vm";
      networking.networkmanager.enable = true;

      time.timeZone = "Europe/Berlin";
      i18n.defaultLocale = "en_GB.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "de_DE.UTF-8";
        LC_IDENTIFICATION = "de_DE.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_NAME = "de_DE.UTF-8";
        LC_NUMERIC = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TELEPHONE = "de_DE.UTF-8";
        LC_TIME = "de_DE.UTF-8";
      };

      console.keyMap = "pl";
      networking.interfaces.ens34.ipv4.addresses = [ { address = "192.168.42.2"; prefixLength = 24; } ];

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

      services.getty.autologinUser = "ramona";
      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [
        vim
        gnupg
        git
        htop
        zsh
      ];

      virtualisation.docker.enable = true;
      virtualisation.vmware.guest.enable = true;

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
      };

      services.openssh.enable = true;
      services.vscode-server.enable = true;

      nix.settings.experimental-features = [ "nix-command flakes" ];

      networking.firewall.enable = false;

      system.stateVersion = "22.11";
    };
  }
 