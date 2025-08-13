_: {
  config = {
    services.nginx = {
      virtualHosts."fleet.services.ramona.fun" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:8080/";

          # fleet seems to use websockets for osquery
          proxyWebsockets = true;
        };
      };
    };
  };
}
