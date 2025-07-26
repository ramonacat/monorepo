{
  config,
  pkgs,
  ...
}: {
  config = {
    age.secrets.rad-environment = {
      file = ../../secrets/rad-environment.age;
    };
    age.secrets.rad-ras-token = {
      file = ../../secrets/rad-ras-token.age;
      owner = "rad";
      mode = "440";
    };
    systemd.services.rad = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        User = "rad";
        ExecStart = "${pkgs.ramona.rad}/bin/rad";
        EnvironmentFile = config.age.secrets.rad-environment.path;
        Restart = "always";
        RestartSec = "5s";
      };
    };
    users.users.rad = {
      isSystemUser = true;
      group = "rad";
    };

    users.groups.rad = {};
  };
}
