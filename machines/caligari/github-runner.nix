{ config, pkgs, lib, ... }:
{
    age.secrets.caligari-github-pat-runner-registration = {
      file = ../../secrets/caligari-github-pat-runner-registration.age;
    };

    services.github-runner = {
        enable = true;
        url = "https://github.com/ramonacat/nix-configs";
        tokenFile = config.age.secrets.caligari-github-pat-runner-registration.path;
        extraLabels = ["nixos"];
    };
}
