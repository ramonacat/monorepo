{config, ...}: {
  config = {
    services.nginx = {
      virtualHosts."jellyfin.ramona.fun" = {
        forceSSL = true;
        enableACME = true;

        locations = {
          "/" = {
            proxyPass = "http://hallewell:8096";
            recommendedProxySettings = true;
          };
          "/socket" = {
            proxyPass = "http://hallewell:8096";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
      config.services.nginx.defaultSSLListenPort
    ];
  };
}
