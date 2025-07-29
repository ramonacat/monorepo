{lib, ...}: {
  config = {
    networking.hostName = "shadowsoul";

    networking = {
      networkmanager.enable = lib.mkForce false;
      useNetworkd = true;
    };
  };
}
