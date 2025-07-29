{config, ...}: {
  imports = [
    ./nginx/host-ramona-fun.nix
  ];
  config = {
    services.nginx = {
      enable = true;
    };

    networking.firewall.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
      config.services.nginx.defaultSSLListenPort
    ];
  };
}
