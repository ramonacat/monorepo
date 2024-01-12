{ config, pkgs, lib, ... }: {
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    user = "ramona";

    dataDir = "/home/ramona/.syncthing-data";
    configDir = "/home/ramona/.config/syncthing";

    settings =
      let otherMachineIds = (lib.attrsets.filterAttrs (key: value: key != config.networking.hostName) (import ../data/syncthing-devices-ids.nix));
      in {
        devices = lib.attrsets.mapAttrs (key: value: { id = value; }) otherMachineIds;

        folders = {
          "shared" = {
            path = "/home/ramona/shared/";
            devices = lib.attrsets.mapAttrsToList (name: value: name) otherMachineIds;
          };
        };
      };
  };

  # For syncthing
  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
