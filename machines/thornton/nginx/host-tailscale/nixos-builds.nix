{config, ...}: {
  config = {
    services.nginx = {
      virtualHosts."${config.networking.hostName}.ibis-draconis.ts.net" = {
        locations."~ /builds/.*" = let
          paths = import ../../../../data/paths.nix;
        in {
          root = paths.${config.networking.hostName}.tailscale-www-root;
        };
      };
    };
  };
}
