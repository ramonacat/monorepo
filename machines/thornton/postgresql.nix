_: {
  imports = [
    ../../modules/postgresql-server.nix
  ];
  config = {
    services = {
      ramona.postgresql-server = {
        enable = true;
        path = "/var/lib/postgresql/17/";
        backup-path = "/var/lib/postgresql-backup";
      };
    };
  };
}
