{
  flake,
  config,
  ...
}:
{
  config = {
    age.secrets.nix-serve-ssh-key.file = ../../secrets/nix-serve-ssh-key.age;
    age.secrets.nix-netrc.file = ../../secrets/nix-netrc.age;

    nix = {
      optimise.automatic = true;
      gc.automatic = true;
      settings = {
        netrc-file = config.age.secrets.nix-netrc.path;
        trusted-public-keys = [
          "nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="
          "main:v6GjP95ntWZJfOZ5MtWKDTAhDWxX+ta1PCaNzh+Oi+c="
        ];
        substituters =
          let
            hosts = flake.hosts.builds-hosts;
          in
          map (x: "ssh://nix-ssh@${x}?ssh-key=${config.age.secrets.nix-serve-ssh-key.path}") hosts;
        fallback = true;
      };
    };
  };
}
