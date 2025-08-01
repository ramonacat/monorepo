{
  config,
  lib,
  ...
}: let
  syncthing-gui-port = 8384;
  syncthing-device-ids = import ../../data/syncthing-devices-ids.nix;
  other-machine-ids = lib.attrsets.filterAttrs (key: _: key != config.networking.hostName) syncthing-device-ids;
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
            hallewell = {id = syncthing-device-ids.hallewell;};
          };
          folders.dls = {
            id = "trnsmsn-dls";
            path = paths.shadowsoul.transmission-downloads;
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
          devices =
            (lib.attrsets.mapAttrs (_: value: {id = value;}) other-machine-ids)
            // {
              shadowsoul = {
                addresses = [
                  "tcp://213.108.112.64:22000"
                ];
                id = syncthing-device-ids.shadowsoul;
              };
            };

          folders = {
            shared.path = lib.mkForce "${paths.hallewell.nas-share}/ramona/shared/";
            dls = {
              id = "trnsmsn-dls";
              path = "${paths.hallewell.nas-root}/dls/";
              devices = lib.attrsets.mapAttrsToList (name: _: name) other-machine-ids;
            };
          };
        };
      }
      else {
        openDefaultPorts = true;
        user = "ramona";

        dataDir = paths.common.syncthing-data;
        configDir = paths.common.syncthing-config;

        settings = {
          devices = lib.attrsets.mapAttrs (_: value: {id = value;}) other-machine-ids;

          folders = {
            "shared" = {
              path = paths.common.ramona-shared;
              devices = lib.attrsets.mapAttrsToList (name: _: name) other-machine-ids;
            };
          };
        };
      }
    );

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [syncthing-gui-port];
}
