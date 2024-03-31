{...}: {
  config = {
    networking.hostName = "caligari";
    services.fail2ban = {
      enable = true;
      ignoreIP = [
        "10.69.0.0/16"
        "100.0.0.0/8"
      ];
    };
    networking.firewall.extraInputRules = ''
      iifname enp41s0 tcp dport 22 drop
    '';
  };
}
