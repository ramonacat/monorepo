{config, ...}: {
  config = {
    age.secrets.nix-serve-key = {
      file = ../../secrets/nix-serve-key.age;
    };

    services.nix-serve = {
      enable = true;
      secretKeyFile = config.age.secrets.nix-serve-key.path;
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.nix-serve.port];
  };
}
