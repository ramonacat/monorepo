{ config, lib, ... }: {
  config = {
    services.frr = lib.mkIf config.ramona.router.enabled {
      configFile = config.ramona.router.frr_config;
      ospfd = {
        enable = true;
      };
      bfdd = {
        enable = true;
      };
    };

    # allow OSPF and BFD from peer routers
    networking.firewall.extraInputRules = ''
      ip saddr 10.255.240.0/20 ip protocol ospfigp accept
      ip saddr 10.255.240.0/20 udp dport { 3784, 3785, 4784 }
    '';
  };
}
