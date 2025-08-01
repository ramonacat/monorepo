{config, ...}: {
  imports = import ../../libs/nix/nix-files-from-dir.nix ./nginx;
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
