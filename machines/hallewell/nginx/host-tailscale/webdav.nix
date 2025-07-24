_: {
  config = {
    services.nginx = {
      virtualHosts."hallewell.ibis-draconis.ts.net" = {
        locations."~ /webdav/.*" = {
          root = "/mnt/nas3/data/ramona/";
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
      services.nginx.serviceConfig.ReadWritePaths = ["/mnt/nas3/data/ramona/webdav/"];
    };
  };
}
