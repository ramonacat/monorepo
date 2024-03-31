{lib, ...}: {
  config = {
    networking.hostName = "shadowmend";

    networking = {
      useDHCP = lib.mkForce false;
      interfaces.enp0s20u1.useDHCP = lib.mkForce true;
      interfaces.enp7s0.useDHCP = lib.mkForce true;
    };
  };
}
