{config, ...}: {
  config = {
    age.secrets.nix-serve-key = {
      file = ../../secrets/nix-serve-key.age;
    };

    services.nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets.nix-serve-key.path;
      port = 5001;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.nix-serve.port];
  };
}
