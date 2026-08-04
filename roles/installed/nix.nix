{
  flake,
  config,
  ...
}:
{
  config = {
    age.secrets = {
      nix-serve-ssh-key.file = ../../secrets/nix-serve-ssh-key.age;
      nix-netrc.file = ../../secrets/nix-netrc.age;
      nix-tokens.file = ../../secrets/nix-tokens.age;
    };
    systemd.services.nix-daemon.serviceConfig = {
      EnvironmentFile = config.age.secrets.nix-tokens.path;
    };

    nix = {
      optimise.automatic = true;
      gc.automatic = true;
      settings = {
        netrc-file = config.age.secrets.nix-netrc.path;
        trusted-public-keys = [
          "nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="
          "main:9Q1Mm+tViVquBw+Q8B5BMsCbOhE2Ig3PcVJvm4BMuRs="
        ];
        substituters =
          let
            hosts = flake.hosts.builds-hosts;
          in
          (map (x: "ssh://nix-ssh@${x}?ssh-key=${config.age.secrets.nix-serve-ssh-key.path}") hosts)
          ++ [ "https://attic.infrastructure.ramona.fun" ];
        fallback = true;
      };
    };
  };
}
