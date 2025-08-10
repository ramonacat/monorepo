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
        trusted-public-keys = ["nix-serve--hallewell:U/8IASkklbxXoFqzevYNdIle1xm3G54u9vUSHzmNaik="];
        substituters = let hosts = flake.hosts.builds-hosts; in builtins.map (x: "https://${x}.ibis-draconis.ts.net/nix-serve/") hosts;
        fallback = true;
      };
    };
  };
}
