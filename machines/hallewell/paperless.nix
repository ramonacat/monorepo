{config, ...}: {
  config = {
    services.paperless = let
      paths = import ../../data/paths.nix;
    in {
      enable = true;
      address = "0.0.0.0";
      domain = config.networking.hostName;
      port = 58080;
      dataDir = "${paths.hallewell.nas-root}/paperless/data/";
      mediaDir = "${paths.hallewell.nas-root}/paperless/media/";
      consumptionDir = "${paths.hallewell.nas-share}/paperless-import/";
      consumptionDirIsPublic = true;
      settings = {
        PAPERLESS_OCR_LANGUAGE = "deu+eng+pol";
      };
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.paperless.port];
  };
}
