{pkgs, ...}: {
  config = {
    services.nginx = {
      virtualHosts."ramona.fun" = {
        forceSSL = true;
        enableACME = true;

        root = "${pkgs.ramona.ramona-fun}/public/";
      };
    };
  };
}
