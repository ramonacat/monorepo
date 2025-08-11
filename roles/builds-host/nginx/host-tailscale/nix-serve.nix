{config, ...}: {
  config = {
    services.nginx.virtualHosts."${config.networking.hostName}.ibis-draconis.ts.net".locations = {
      "/nix-serve/" = {
        proxyPass = "http://localhost:${builtins.toString config.services.nix-serve.port}/";
      };
    };
  };
}
