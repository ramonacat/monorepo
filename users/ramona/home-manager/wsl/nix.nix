{
  pkgs,
  flake,
  ...
}: {
  config = {
    nix = {
      package = pkgs.nix;
      gc.automatic = true;
      settings = {
        trusted-public-keys = ["nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik=" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
        substituters = let
          hosts = flake.hosts.builds-hosts;
        in
          (builtins.map (x: "ssh://nix-ssh@${x}") hosts) ++ ["https://cache.nixos.org/"];
      };
    };
  };
}
