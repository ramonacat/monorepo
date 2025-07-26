{
  config,
  lib,
  ...
}: {
  services.syncthing =
    if config.networking.hostName == "shadowsoul"
    then {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      guiAddress = "0.0.0.0:8384";
      user = "transmission";

      settings = {
        devices = {
          hallewell = {id = "WGH223K-BA7PTFL-DG22PJS-DJY3OJP-PGNVTHO-7S6QVAV-ALDTUWY-7NOLXAF";};
        };
        folders.dls = {
          id = "trnsmsn-dls";
          path = "/var/lib/transmission/Downloads/";
          devices = ["hallewell"];
        };
      };
    }
    else {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      openDefaultPorts = true;
      user = "ramona";
      guiAddress = "0.0.0.0:8384";

      dataDir = "/home/ramona/.syncthing-data";
      configDir = "/home/ramona/.config/syncthing";

      settings = let
        otherMachineIds = lib.attrsets.filterAttrs (key: _: key != config.networking.hostName) (import ../../data/syncthing-devices-ids.nix);
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

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [8384];
}
