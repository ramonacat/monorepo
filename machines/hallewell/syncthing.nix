{lib, ...}: {
  config = {
    services.syncthing = {
      user = lib.mkForce "nas";
      dataDir = lib.mkForce "/mnt/nas3/syncthing/data/";
      configDir = lib.mkForce "/mnt/nas3/syncthing/config/";

      settings = {
        devices.seedbox.id = "2SFTGDS-ZURKFAZ-OTUE3XU-7LUQP5T-ZT34A3F-JBASCK5-T5EZOFI-QVBURAM";
        devices.shadowsoul.id = "7NXR3IB-O4X73UQ-YVL6C5D-WEVRNVZ-5R6MIZH-P73UNPX-LRNJV6K-UEJNUQS";

        folders = {
          shared.path = lib.mkForce "/mnt/nas3/data/shared/";
          stuff = {
            id = "4xhsx-qnnqq";
            path = "/mnt/nas3/stuff/";
            devices = ["seedbox"];
          };
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
