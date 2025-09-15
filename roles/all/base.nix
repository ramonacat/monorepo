{pkgs, ...}: {
  config = {
    security.sudo.wheelNeedsPassword = true;
    users.mutableUsers = false;

    environment.systemPackages = with pkgs; [
      htop
      iotop
      perf
    ];

    system.stateVersion = "22.11";
    zramSwap.enable = true;
  };
}
