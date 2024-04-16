{lib, ...}: {
  config = {
    networking = {
      hostName = "hallewell";

      useDHCP = lib.mkForce false;
      interfaces.eno1.useDHCP = lib.mkForce true;
    };
  };
}
