{lib, ...}: {
  config = {
    networking.hostName = "shadowsoul";

    networking = {
      useDHCP = lib.mkForce true;
    };
  };
}
