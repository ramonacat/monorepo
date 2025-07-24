_: {
  config = {
    services.nginx = {
      virtualHosts."hallewell.ibis-draconis.ts.net" = {
        locations."~ /builds/.*" = {
          root = "/var/www/hallewell.ibis-draconis.ts.net/";
        };
      };
    };
  };
}
