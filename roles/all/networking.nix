{ lib, ... }: {
  config = {
    networking = {
      useDHCP = lib.mkForce true;
      nftables.enable = true;
      useNetworkd = true;
    };

    # This timeouts during rebuilds
    systemd.network.wait-online.enable = false;

    # The default metric is 1024, which is an issue in case of OSPF, which will install remote routes with lower metrics
    systemd.network.networks."10-default" = {
      matchConfig = {
        Kind = "!*";
        Type = "ether";
      };
      DHCP = "yes";
      dhcpV4Config = {
        RouteMetric = 5;
      };
    };
  };
}
