{pkgs, ...}: {
  config = {
    services.nginx = {
      virtualHosts."sawin.gallery" = {
        forceSSL = true;
        enableACME = true;

        root = "${pkgs.ramona.sawin-gallery}";
        extraConfig = ''
          auth_basic "..."
          auth_basic_user_file ${./host-sawin-gallery/basic_auth.htpasswd}
        '';
      };
    };
  };
}
