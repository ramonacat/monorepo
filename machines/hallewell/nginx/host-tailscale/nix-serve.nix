{config, ...}: {
  config = {
    services.nginx.virtualHosts."hallewell.ibis-draconis.ts.net".locations = {
      "~ /nix-serve/.*" = {
        proxyPass = "http://localhost:${builtins.toString config.services.nix-serve.port}/";
      };
    };
  };
}
