{config, ...}: {
  imports = [
    ./host-ramona-fun.nix
    ./host-savin-gallery.nix
    ./host-sawin-gallery
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
