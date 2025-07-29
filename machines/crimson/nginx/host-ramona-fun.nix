{pkgs, ...}: {
  config = {
    services.nginx = {
      virtualHosts."ramona.fun" = {
        forceSSL = true;
        enableACME = true;

        root = "${pkgs.ramona.ramona-fun}/public/";
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "ramona@luczkiewi.cz";
    };
  };
}
