{
  pkgs,
  flake,
  config,
  ...
}:
{
  config = {
    age.secrets = {
      attic-admin = {
        file = ../../../../secrets/attic-admin.age;
        path = "${config.home.homeDirectory}/.config/attic/config.toml";
      };
      nix-netrc = {
        file = ../../../../secrets/nix-netrc.age;
        path = "${config.home.homeDirectory}/.config/nix/netrc";
      };
      nix-tokens = {
        file = ../../../../secrets/nix-tokens.age;
        path = "${config.home.homeDirectory}/.config/nix/tokens";
      };
    };

    nix = {
      package = pkgs.nix;
      gc.automatic = true;
      settings = {
        netrc-file = config.age.secrets.nix-netrc.path;

        trusted-public-keys = [
          "nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "main:v6GjP95ntWZJfOZ5MtWKDTAhDWxX+ta1PCaNzh+Oi+c="
        ];
        substituters =
          let
            hosts = flake.hosts.builds-hosts;
          in
          (map (x: "ssh://nix-ssh@${x}") hosts)
          ++ [
            "https://cache.nixos.org/"
            "https://attic.infrastructure.ramona.fun/main"
          ];
        fallback = true;
      };
    };
  };
}
