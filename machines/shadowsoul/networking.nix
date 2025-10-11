_: {
  config = {
    networking.hostName = "shadowsoul";

    systemd.network.netdevs = {
      bond0 = {
        enable = true;
        netdevConfig = {
          Kind = "bond";
          Name = "bond0";
        };
        bondConfig = {
          Mode = "balance-rr";
        };
      };
    };
    systemd.network.networks = {
      enp0s31 = {
        matchConfig = {Name = "enp0s31";};
        networkConfig = {Bond = "bond0";};
      };
      enp1s0 = {
        matchConfig = {Name = "enp1s0";};
        networkConfig = {Bond = "bond0";};
      };
    };
  };
}
