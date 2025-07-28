_: {
  config = let
    paths = import ../../../../data/paths.nix;
  in {
    services.nginx = {
      virtualHosts."hallewell.ibis-draconis.ts.net" = {
        locations."~ /webdav/.*" = {
          root = "${paths.hallewell.nas-share}/ramona/";
          extraConfig = ''
            dav_methods PUT DELETE MKCOL COPY MOVE;
            dav_ext_methods PROPFIND OPTIONS;
            dav_access all:rw;

            create_full_put_path on;
          '';
        };
      };
    };

    systemd = {
      services.nginx.serviceConfig.ReadWritePaths = ["${paths.hallewell.nas-share}/ramona/webdav/"];
    };
  };
}
