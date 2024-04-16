{lib, ...}: {
  config = {
    services.syncthing = {
      user = lib.mkForce "nas";
      dataDir = lib.mkForce "/mnt/nas3/syncthing/data/";
      configDir = lib.mkForce "/mnt/nas3/syncthing/config/";

      settings = {
        devices.seedbox.id = "2SFTGDS-ZURKFAZ-OTUE3XU-7LUQP5T-ZT34A3F-JBASCK5-T5EZOFI-QVBURAM";

        folders.shared.path = lib.mkForce "/mnt/nas3/data/shared/";
        folders.stuff = {
          id = "4xhsx-qnnqq";
          path = "/mnt/nas3/stuff/";
          devices = ["seedbox"];
        };
      };
    };
  };
}
