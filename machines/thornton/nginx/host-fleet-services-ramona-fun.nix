_: {
  config = {
    services.nginx = {
      virtualHosts."fleet.services.ramona.fun" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8080/";

            # fleet seems to use websockets for osquery
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
