{nixpkgs}: {
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./base/pam.nix
  ];

  config = let
    nixpkgsPath = "/etc/channels/nixpkgs";
  in {
    services.openssh.enable = true;
    # this service does nothing useful but breaks rebuilds if it's restarted
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    boot = {
      kernelParams = [
        # this is needed for iotop
        "delayacct"
      ];
      kernelPackages = lib.mkOverride 500 pkgs.linuxPackages_latest;
      kernel.features.debug = true;
    };

    security.sudo.wheelNeedsPassword = true;
    users.mutableUsers = false;

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

    environment.systemPackages = with pkgs; [
      vim
      gnupg
      git
      htop
      sysstat
      iotop
      tmux
      config.boot.kernelPackages.perf
      cryptsetup
      sbctl
    ];

    networking = {
      useDHCP = false;
      networkmanager.enable = true;
      wireless.enable = false;
      nftables.enable = true;
    };

    console.keyMap = "pl";
    system.stateVersion = "22.11";

    nix = {
      registry.nixpkgs.flake = nixpkgs;
      settings.trusted-users = ["@wheel"];
      settings.experimental-features = ["nix-command flakes"];
      nixPath = [
        "nixpkgs=${nixpkgsPath}"
      ];
    };

    systemd.tmpfiles.rules = [
      "L+ ${nixpkgsPath}  - - - - ${nixpkgs}"
    ];
  };
}
