_: {
  config = {
    networking = {
      hostName = "hallewell";
      enableIPv6 = false;
    };
    systemd.network.networks."10-ether" = {
      matchConfig = {name = "eno1";};
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
        LinkLocalAddressing = false;
      };
    };
  };
}
