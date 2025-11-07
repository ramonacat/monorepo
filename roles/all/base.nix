{pkgs, ...}: {
  config = {
    security.sudo.wheelNeedsPassword = true;
    users.mutableUsers = false;

    environment.systemPackages = with pkgs; [
      atop
      htop
      iotop
      neovim
      perf
      sysstat
    ];

    system.stateVersion = "22.11";
    zramSwap.enable = true;
  };
}
