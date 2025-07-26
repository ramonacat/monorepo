{
  config,
  pkgs,
  ...
}: {
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
