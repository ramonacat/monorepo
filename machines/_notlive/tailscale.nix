{pkgs, ...}: {
  config = {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = ["--advertise-exit-node"];
    };
    environment.systemPackages = with pkgs; [
      tailscale
    ];
  };
}
