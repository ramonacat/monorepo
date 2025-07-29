{lib, ...}: {
  config = {
    networking = {
      useDHCP = lib.mkForce true;
      wireless.enable = false;
      nftables.enable = true;
      useNetworkd = true;
    };
  };
}
