{config, ...}: {
  imports = [
    ./host-fleet-services-ramona-fun.nix
  ];
  config = {
    services.nginx = {
      enable = true;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
      config.services.nginx.defaultSSLListenPort
    ];
  };
}
