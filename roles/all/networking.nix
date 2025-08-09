{lib, ...}: {
  config = {
    networking = {
      useDHCP = lib.mkForce true;
      nftables.enable = true;
      useNetworkd = true;
    };

    # This timeouts during rebuilds
    systemd.network.wait-online.enable = false;
  };
}
