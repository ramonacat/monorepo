{config, ...}: {
  config = {
    services.nginx = {
      virtualHosts."${config.networking.hostName}.ibis-draconis.ts.net" = {
        locations."~ /builds/.*" = {
          root = "/var/www/${config.networking.hostName}.ibis-draconis.ts.net";
        };
      };
    };
  };
}
