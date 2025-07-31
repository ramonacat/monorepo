_: {
  config = {
    services.nginx = {
      virtualHosts."savin.gallery" = {
        forceSSL = true;
        enableACME = true;

        globalRedirect = "sawin.gallery";
        redirectCode = 301;
      };
    };
  };
}
