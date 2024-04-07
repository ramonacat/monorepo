{config, ...}: {
  config = {
    age.secrets.transmission-credentials = {
      file = ../../secrets/transmission-credentials.age;
      group = "transmission";
      mode = "440";
    };

    services.transmission = {
      enable = true;
      openFirewall = true;
      performanceNetParameters = true;
      credentialsFile = config.age.secrets.transmission-credentials.path;
      settings = {
        peer-port = 51413;
        peer-port-random-on-start = false;
        utp-enabled = true;
        rpc-whitelist = "127.0.0.1,::1,100.0.0.0/8";
        rpc-host-whitelist-enabled = false;
        rpc-bind-address = "0.0.0.0";
        peer-limit-global = 1000;
        peer-limit-per-torrent = 500;
        lpd-enabled = true;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [9001];
  };
}
