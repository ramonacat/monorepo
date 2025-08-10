_: {
  imports = [
    ./host-tailscale
  ];
  config = {
    services.nginx = {
      # This matters for webdav, where big files can be uploaded
      clientMaxBodySize = "1024m";
    };
  };
}
