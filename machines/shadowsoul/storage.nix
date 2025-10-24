_: {
  config = {
    services.autotierfs = {
      enable = true;
      settings = {
        "/var/lib/transmission/Downloads" = {
          Global = {
            "Tier Period" = 180;
          };
          Local = {
            Path = "/var/local-tier";
            Quota = "80%";
          };
          Remote = {
            Path = "/mnt/remote-tier";
          };
        };
      };
    };
  };
}
