{pkgs, ...}: {
  config = {
    systemd.services.fleet = {
      environment = {
        FLEET_MYSQL_PROTOCOL = "unix";
        FLEET_MYSQL_ADDRESS = "/var/run/mysqld/mysqld.sock";
        FLEET_SERVER_TLS = "false";
      };
      serviceConfig = {
        User = "fleet";
        Group = "fleet";
        LimitNOFILE = 8192;
        ExecStart = "${pkgs.fleet}/bin/fleet serve";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    users.users.fleet = {
      isSystemUser = true;
      group = "fleet";
    };

    users.groups.fleet = {};
  };
}
