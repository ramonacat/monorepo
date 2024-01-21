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
}
