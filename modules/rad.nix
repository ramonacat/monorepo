{
  config,
  pkgs,
  ...
}: {
  config = {
    age.secrets.rad-environment = {
      file = ../secrets/rad-environment.age;
    };
    systemd.services.rad = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${pkgs.ramona.rad}/bin/rad";
        EnvironmentFile = config.age.secrets.rad-environment.path;
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
