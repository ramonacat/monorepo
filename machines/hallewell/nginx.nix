{config, ...}: {
  imports = import ../../libs/nix/nix-files-from-dir.nix ./nginx;
  config = {
    services.nginx = {
      enable = true;
      # This matters for example for webdav, where big files can be uploaded
      clientMaxBodySize = "1024m";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
      config.services.nginx.defaultSSLListenPort
    ];
  };
}
