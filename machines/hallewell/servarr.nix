{
  config,
  pkgs,
  ...
}: {
  config = let
    flaresolver-port = 8191;
  in {
    services = {
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
      lidarr = {
        enable = true;
        user = "nas";

        settings = {
          server.port = 8991;
        };
      };
      prowlarr = {
        enable = true;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.radarr.settings.server.port
      config.services.sonarr.settings.server.port
      config.services.lidarr.settings.server.port
      config.services.prowlarr.settings.server.port
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

    services.restic.backups.servarr = import ../../libs/nix/mk-restic-config.nix {inherit config pkgs;} {
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        RandomizedDelaySec = "30m";
      };
      paths = [
        config.services.sonarr.dataDir
        config.services.radarr.dataDir
        config.services.lidarr.dataDir
        # this path seems to be hardcoded in the service definition
        "/var/lib/prowlarr"
      ];
    };
  };
}
