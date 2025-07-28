# TODO move this to the big common config in _notlive/?
{lib, ...}: {
  config = {
    services.syncthing = let
      paths = import ../../data/paths.nix;
    in {
      user = lib.mkForce "nas";
      dataDir = lib.mkForce "${paths.hallewell.nas-root}/syncthing/data/";
      configDir = lib.mkForce "${paths.hallewell.nas-root}/config/";

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
    };
  };
}
