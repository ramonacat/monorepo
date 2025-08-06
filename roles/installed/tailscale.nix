{
  pkgs,
  config,
  ...
}: {
  config = {
    age.secrets.tailscale-auth-key = {
      file = ../../secrets/tailscale-auth-key.age;
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraUpFlags = ["--advertise-exit-node"];
      authKeyFile = config.age.secrets.tailscale-auth-key.path;
    };
    environment.systemPackages = with pkgs; [
      tailscale
    ];
  };
}
