_: {
  config = {
    services.nginx = {
      virtualHosts."hallewell.ibis-draconis.ts.net" = {
        locations."~ /builds/.*" = let
          paths = import ../../../../data/paths.nix;
        in {
          root = paths.hallewell.tailscale-www-root;
        };
      };
    };
  };
}
