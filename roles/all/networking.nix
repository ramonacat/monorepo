{lib, ...}: {
  config = {
    networking = {
      useDHCP = lib.mkForce true;
      wireless.enable = false;
      nftables.enable = true;
      useNetworkd = true;
    };

    # This timeouts during rebuilds
    systemd.network.wait-online.enable = false;
  };
}
