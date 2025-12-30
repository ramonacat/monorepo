{config, ...}: {
  imports = [
    ./backup.nix
  ];
  config = {
    services.immich = let
      paths = import ../../../data/paths.nix;
    in {
      enable = true;
      host = "0.0.0.0";
      mediaLocation = paths.hallewell.immich;
      # null gives access to all devices
      accelerationDevices = null;
      database = {
        enableVectors = false;
        enableVectorChord = true;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.immich.port];
  };
}
