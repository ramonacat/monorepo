_: {
  config = {
    services = {
      jackett.enable = true;
      radarr = {
        enable = true;
        user = "nas";
      };
      sonarr = {
        enable = true;
        user = "nas";
      };
      readarr = {
        enable = true;
        user = "nas";
      };
    };

    fileSystems."/var/lib/transmission/Downloads" = {
      device = "shadowsoul:/var/lib/transmission/Downloads";
      fsType = "nfs";
      options = ["x-systemd.after=tailscaled.service"];
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      9117 # jackett
      7878 # radarr
      8990 # sonarr
      8787 # readarr
      8191 # flaresolverr
    ];

    virtualisation.oci-containers.containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = ["0.0.0.0:8191:8191"];
      environment = {
        LOG_LEVEL = "info";
      };
    };
  };
}
