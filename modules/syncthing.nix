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

  # For syncthing
  networking.firewall.allowedTCPPorts = [22000];
  networking.firewall.allowedUDPPorts = [22000 21027];
}
