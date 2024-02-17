{ config, pkgs, lib, ... }:
{
  age.secrets.caligari-github-pat-runner-registration = {
    file = ../../secrets/caligari-github-pat-runner-registration.age;
  };

  services.github-runners = builtins.listToAttrs (builtins.map
    (i: {
      name = "caligari-${toString i}";
      value = {
        enable = true;
        url = "https://github.com/ramonacat/nix-configs";
        tokenFile = config.age.secrets.caligari-github-pat-runner-registration.path;
        extraLabels = [ "nixos" ];
      };
    })
    (lib.range 0 6));

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkRskZZaMsOngUvKYgL8K6t5FBhMurjTkqbfxNLj0wE ramona@moonfall" # this is the key that's used in CI
  ];
}
