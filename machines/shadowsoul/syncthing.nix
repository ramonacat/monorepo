{lib, ...}: {
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    guiAddress = "0.0.0.0:8384";
    user = lib.mkForce "transmission";

    settings = lib.mkForce {
      devices = {
        hallewell = {id = "WGH223K-BA7PTFL-DG22PJS-DJY3OJP-PGNVTHO-7S6QVAV-ALDTUWY-7NOLXAF";};
      };
      folders.dls = {
        id = "trnsmsn-dls";
        path = "/var/lib/transmission/Downloads/";
        devices = ["hallewell"];
      };
    };
  };
}
