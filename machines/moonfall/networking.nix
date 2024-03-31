{lib, ...}: {
  config = {
    networking.hostName = "moonfall";

    networking.useDHCP = lib.mkForce false;
    networking.interfaces.eno1.useDHCP = lib.mkForce true;
    networking.interfaces.eno1.wakeOnLan = {
      enable = true;
    };
  };
}
