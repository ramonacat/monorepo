_: {
  config = {
    networking = {
      hostName = "thornton";
      interfaces.enp1s0.ipv6.addresses = [
        # TODO: set the actual ip once we get it from hetzner
      ];
      defaultGateway6 = {
        address = "fe80::1";
        interface = "enp1s0";
      };
    };
  };
}
