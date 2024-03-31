{pkgs, ...}: {
  age.secrets.rabbitmq-ha = {
    file = ../../secrets/rabbitmq-ha.age;
    group = "home-automation-secrets";
    mode = "440";
  };

  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [docker-compose];

  users.groups.home-automation-secrets = {};

  systemd.services.home-automation = {
    wantedBy = ["multi-user.target"];
    after = ["network.target" "rabbitmq.target"];
    description = "Home automation";
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      ExecStart = "${pkgs.ramona.home-automation}/bin/home-automation";
      SupplementaryGroups = "home-automation-secrets";
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
