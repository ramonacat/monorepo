_: {
  config = {
    networking = {
      hostName = "crimson";
      interfaces.enp1s0.ipv6.addresses = [
        {
          address = "2a01:4f9:c011:9c81::1";
          prefixLength = 64;
        }
      ];
    };
  };
}
