{nixpkgs}: {
  config,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (import ./base/nix.nix {inherit nixpkgs;})

    ./base/kernel.nix
    ./base/locale.nix
    ./base/networking.nix
    ./base/pam.nix
    ./base/ssh.nix
  ];

  config = {
    security.sudo.wheelNeedsPassword = true;
    users.mutableUsers = false;

    environment.systemPackages = with pkgs; [
      htop
      iotop
      config.boot.kernelPackages.perf
    ];

    system.stateVersion = "22.11";
  };
}
