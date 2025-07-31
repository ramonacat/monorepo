{config, ...}: {
  imports = [
    ./nginx/host-ramona-fun.nix
    ./nginx/host-savin-gallery.nix
    ./nginx/host-sawin-gallery.nix
  ];
  config = {
    services.nginx = {
      enable = true;
    };

    networking.firewall.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
      config.services.nginx.defaultSSLListenPort
    ];

    security.acme = {
      acceptTerms = true;
      defaults.email = "ramona@luczkiewi.cz";
    };
  };
}
