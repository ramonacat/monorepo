_: {
  imports = [
    ../../modules/postgresql-server.nix
  ];
  config = {
    services = let
      paths = import ../../data/paths.nix;
    in {
      ramona.postgresql-server = {
        enable = true;
        path = "${paths.hallewell.nas-root}/postgresql/17/";
        backup-path = "${paths.hallewell.nas-root}/postgres-backup";
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [5432];
  };
}
