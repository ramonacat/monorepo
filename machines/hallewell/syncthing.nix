{lib, ...}: {
  config = {
    services.syncthing = {
      user = lib.mkForce "nas";
      dataDir = lib.mkForce "/mnt/nas3/syncthing/data/";
      configDir = lib.mkForce "/mnt/nas3/syncthing/config/";

      settings = {
        devices.shadowsoul = {
          addresses = [
            "tcp://213.108.112.64:22000"
          ];
          id = "7NXR3IB-O4X73UQ-YVL6C5D-WEVRNVZ-5R6MIZH-P73UNPX-LRNJV6K-UEJNUQS";
        };

        folders = {
          shared.path = lib.mkForce "/mnt/nas3/data/shared/";
          dls = {
            id = "trnsmsn-dls";
            path = "/mnt/nas3/dls/";
            devices = ["shadowsoul"];
          };
        };
      };
    };
  };
}
