{
  pkgs,
  ...
}:
{
  config = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--advertise-exit-node" ];
      authKeyFile = "/var/ramona/tailscale/key";
    };
    environment.systemPackages = with pkgs; [
      tailscale
    ];
  };
}
