{config, ...}: {
  imports = [
    ./nginx/host-tailscale.nix
  ];
  config = {
    services.nginx = {
      enable = true;
      # This matters for example for webdav, where big files can be uploaded
      clientMaxBodySize = "1024m";
      logError = "stderr debug";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
      config.services.nginx.defaultSSLListenPort
    ];
  };
}
