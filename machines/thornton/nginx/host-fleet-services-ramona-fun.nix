_: {
  config = {
    services.nginx = {
      virtualHosts."fleet.services.ramona.fun" = {
        forceSSL = true;
        enableACME = true;
        locations = let
          grpcConfig = ''
            grpc_pass grpc://127.0.0.1:8080;
            grpc_set_header Host $host;
            grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_buffering off;
          '';
        in {
          "/" = {
            proxyPass = "http://127.0.0.1:8080/";

            # fleet seems to use websockets for osquery
            proxyWebsockets = true;
          };

          "/api/v1/fleet/" = {
            extraConfig = grpcConfig;
          };

          "/api/v1/osquery/" = {
            extraConfig = grpcConfig;
          };
        };
      };
    };
  };
}
