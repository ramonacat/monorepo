_: {
  networking.hostName = "killian";

  systemd.network = {
    netdevs."05-dummy0-k8s-ip".netdevConfig = {
      Kind = "dummy";
      Name = "dummy0-k8s-ip";
    };
    networks."05-dummy0-k8s-ip" = {
      matchConfig = {
        Name = "dummy0-k8s-ip";
      };
      networkConfig = {
        Address = "10.64.0.16/32";
      };
      linkConfig = {
        ActivationPolicy = "always-up";
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
      host = "d.rumanowski.com";
      available_ports = [
        49153
        49155
      ];
    };
  };
}
