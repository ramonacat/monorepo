_: {
  networking.hostName = "depraysie";

  ramona.router = {
    enabled = true;
    wireguard = {
      host = "depraysie.devices.i.ramona.fun";
      available_ports = [
        51820
        51821
        51822
        51823
        51824
        51825
        51826
        51827
        51828
        51829
      ];
    };
  };
}
