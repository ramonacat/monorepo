{pkgs, ...}: {
  config = {
    systemd.services.fleet = {
      environment = {
        FLEET_MYSQL_PROTOCOL = "unix";
        FLEET_SERVER_TLS = "false";
      };
      unitConfig = {
        User = "fleet";
        Group = "fleet";
        LimitNOFILE = 8192;
        ExecStart = "${pkgs.fleet}/bin/fleet serve";
        EnvironmentFile = "";
      };
    };

    users.users.fleet = {
      isSystemUser = true;
      group = "fleet";
    };

    users.groups.fleet = {};
  };
}
