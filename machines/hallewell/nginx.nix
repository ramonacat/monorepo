_: {
  imports = [
    ./nginx/host-tailscale.nix
  ];
  config = {
    services.nginx = {
      enable = true;
      # This matters for example for webdav, where big files can be uploaded
      clientMaxBodySize = "1024m";
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [80 443];
  };
}
