{...}: {
  config = {
    services.nginx = {
      enable = true;

      virtualHosts = {
        "ramona.fun" = {
          forceSSL = true;
          enableACME = true;
          root = "/var/www/ramona.fun/";
        };
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "ramona@luczkiewi.cz";
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
