{
  config,
  lib,
  ...
}: let
  syncthing-gui-port = 8384;
in {
  services.syncthing = let
    paths = import ../../data/paths.nix;
  in
    {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      guiAddress = "0.0.0.0:${builtins.toString syncthing-gui-port}";
    }
    // (
      if config.networking.hostName == "shadowsoul"
      then {
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
      else if config.networking.hostName == "hallewell"
      then {
        user = lib.mkForce "nas";
        dataDir = lib.mkForce "${paths.hallewell.nas-root}/syncthing/data/";
        configDir = lib.mkForce "${paths.hallewell.nas-root}/syncthing/config/";

        settings = {
          devices.shadowsoul = {
            addresses = [
              "tcp://213.108.112.64:22000"
            ];
            id = "7NXR3IB-O4X73UQ-YVL6C5D-WEVRNVZ-5R6MIZH-P73UNPX-LRNJV6K-UEJNUQS";
          };

          folders = {
            shared.path = lib.mkForce "${paths.hallewell.nas-share}/ramona/shared/";
            dls = {
              id = "trnsmsn-dls";
              path = "${paths.hallewell.nas-root}/dls/";
              devices = ["shadowsoul"];
            };
          };
        };
      }
      else {
        openDefaultPorts = true;
        user = "ramona";

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
      }
    );

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [syncthing-gui-port];
}
