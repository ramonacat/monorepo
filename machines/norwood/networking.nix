_: {
  networking.hostName = "norwood";

  systemd.network = {
    netdevs."05-dummy0-k8s-ip".netdevConfig = {
      Kind = "dummy";
      Name = "dummy0-k8s-ip";
    };
    networks = {
      "05-dummy0-k8s-ip" = {
        matchConfig = {
          Name = "dummy0-k8s-ip";
        };
        networkConfig = {
          Address = "10.64.0.17/32";
        };
        linkConfig = {
          ActivationPolicy = "always-up";
        };
      };
      "05-eth0" = {
        matchConfig = {
          MACAddress = "00:50:56:6a:00:01";
        };
        networkConfig = {
          Address = "185.189.2.7/22";
          DNS = [
            "195.179.224.53"
            "209.126.15.53"
          ];
        };
        routes = [
          {
            Gateway = "185.189.0.1";
            GatewayOnLink = true;
            Destination = "0.0.0.0/0";
          }
        ];
      };
    };
  };

  ramona = {
    router = {
      enabled = true;
      interfaces = [
        {
          name_pattern = "dummy0-k8s-ip";
          cost = 1;
          kind = "Passive";
        }
      ];
    };
    wireguard = {
      enabled = true;
    };
  };
}
