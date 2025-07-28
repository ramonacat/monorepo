{config, ...}: {
  config = let
    flaresolver-port = 8191;
  in {
    services = {
      jackett.enable = true;
      radarr = {
        enable = true;
        user = "nas";
      };
      sonarr = {
        enable = true;
        user = "nas";

        settings = {
          server.port = 8990;
        };
      };
    };

    fileSystems."/var/lib/transmission/Downloads" = {
      device = "shadowsoul:/var/lib/transmission/Downloads";
      fsType = "nfs";
      options = ["x-systemd.after=tailscaled.service"];
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.jackett.port
      config.services.radarr.settings.server.port
      config.services.sonarr.settings.server.port
      flaresolver-port
    ];

    virtualisation.oci-containers.containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = ["0.0.0.0:${builtins.toString flaresolver-port}:${builtins.toString flaresolver-port}"];
      environment = {
        LOG_LEVEL = "debug";
      };
      extraOptions = ["--network=host"];
    };
  };
}
