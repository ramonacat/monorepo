{ pkgs, ... }: {
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

      ramona.r
    ];

    system.stateVersion = "22.11";
    zramSwap.enable = true;
  };
}
