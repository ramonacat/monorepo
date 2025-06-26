_: {
  imports = [
    ./nginx/webdav.nix
  ];
  config = {
    services.nginx = {
      enable = true;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [80 443];
  };
}
