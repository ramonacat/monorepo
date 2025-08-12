_: {
  config = {
    services.nginx = {
      virtualHosts."fleet.services.ramona.fun" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:8080/";
        };
      };
    };
  };
}
