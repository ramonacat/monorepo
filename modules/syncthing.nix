{
  config,
  lib,
  ...
}: {
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    user = "ramona";
    guiAddress = "0.0.0.0:8384";

    dataDir = "/home/ramona/.syncthing-data";
    configDir = "/home/ramona/.config/syncthing";

    settings = let
      otherMachineIds = lib.attrsets.filterAttrs (key: _: key != config.networking.hostName) (import ../data/syncthing-devices-ids.nix);
    in {
      devices = lib.attrsets.mapAttrs (_: value: {id = value;}) otherMachineIds;

      folders = {
        "shared" = {
          path = "/home/ramona/shared/";
          devices = lib.attrsets.mapAttrsToList (name: _: name) otherMachineIds;
        };
      };
    };
  };

  networking.firewall = {
    # Public syncing traffic
    allowedTCPPorts = [22000];
    allowedUDPPorts = [22000 21027];

    # Web GUI
    interfaces.tailscale0.allowedTCPPorts = [8384];
  };
}
