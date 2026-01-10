{
  config,
  pkgs,
  ...
}: {
  config = {
    age.secrets.transmission-credentials = {
      file = ../../secrets/transmission-credentials.age;
      group = "transmission";
      mode = "440";
    };

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openFirewall = true;
      performanceNetParameters = true;
      credentialsFile = config.age.secrets.transmission-credentials.path;
      settings = {
        download-queue-size = 15;
        lpd-enabled = true;
        peer-limit-global = 1000;
        peer-limit-per-torrent = 500;
        peer-port = 51413;
        peer-port-random-on-start = false;
        ratio-limit = 1.5;
        ratio-limit-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-host-whitelist-enabled = false;
        rpc-port = 9091;
        rpc-whitelist = "127.0.0.1,::1,100.*.*.*";
        upload-slots-per-torrent = 50;
        utp-enabled = true;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.transmission.settings.rpc-port];
  };
}
