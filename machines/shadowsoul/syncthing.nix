_: {
  services.syncthing = {
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
        path = "/var/lib/transmission/downloads/";
        devices = ["hallewell"];
      };
    };
  };
  networking.firewall = {
    # Public syncing traffic
    allowedTCPPorts = [22000];
    allowedUDPPorts = [22000 21027];

    # Web GUI
    interfaces.tailscale0.allowedTCPPorts = [8384];
  };
}
