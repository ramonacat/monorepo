_: {
  config = {
    services.navidrome = {
      enable = true;
      user = "nas";
      group = "nas";
      settings = {
        Address = "0.0.0.0";
        TranscodingCacheSize = "10G";
        MusicFolder = "/mnt/nas3/data/Music";
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [4533];
  };
}
