{ config, lib, ... }: {
  config = {
    services.bird = lib.mkIf config.ramona.router.enabled {
      enable = true;
      config = ''
        log stderr all;

        include "${config.ramona.router.bird_config}";
      '';
      checkConfig = false;
    };

    # allow OSPF and BFD from peer routers
    networking.firewall.extraInputRules = ''
      ip saddr 10.255.240.0/20 ip protocol ospfigp accept
      ip saddr 10.255.240.0/20 udp dport { 3784, 3785, 4784 } accept
    '';
  };
}
