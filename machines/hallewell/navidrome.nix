_: {
  config = {
    services.navidrome = let
      paths = import ../../data/paths.nix;
    in {
      enable = true;
      user = "nas";
      group = "nas";
      settings = {
        Address = "0.0.0.0";
        TranscodingCacheSize = "10G";
        MusicFolder = "${paths.hallewell.nas-share}/Music";
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [4533];
  };
}
