{ config, ... }: {
  config = {
    services.snmpd = {
      enable = true;
      configText = ''
        com2sec notConfigUser  default       public
        group   notConfigGroup v2c           notConfigUser
        view all    included  .1                               80
        access  notConfigGroup ""      any       noauth    exact  all none none
      '';
    };

    networking.firewall.interfaces.enp1s0.allowedUDPPorts = [ config.services.snmpd.port ];
  };
}
