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
      bond0 = {
        matchConfig = {Name = "bond0";};
        networkConfig = {
          DHCP = true;
          BindCarrier = ["enp0s31f6" "enp1s0"];
        };
      };
      "30-ethernet-enp0s31f6" = {
        matchConfig = {Name = "enp0s31f6";};
        networkConfig = {Bond = "bond0";};
      };
      "30-ethernet-enp1s0" = {
        matchConfig = {Name = "enp1s0";};
        networkConfig = {Bond = "bond0";};
      };
    };
  };
}
