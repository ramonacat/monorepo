{lib, ...}: {
  config = {
    networking = {
      hostName = "moonfall";

      useDHCP = lib.mkForce false;
      interfaces.eno1.useDHCP = lib.mkForce true;
      interfaces.eno1.wakeOnLan = {
        enable = true;
      };
    };
  };
}
