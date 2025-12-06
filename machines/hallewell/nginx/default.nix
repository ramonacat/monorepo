_: {
  imports = [
    ./host-jellyfin-ramona-fun
    ./host-tailscale
  ];
  config = {
    services.nginx = {
      # This matters for webdav, where big files can be uploaded
      clientMaxBodySize = "1024m";
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "ramona@luczkiewi.cz";
    };
  };
}
