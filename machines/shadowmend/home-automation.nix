{ homeAutomationPackage }:
{ config, pkgs, lib, ... }:
{
  age.secrets.rabbitmq-ha = {
    file = ../../secrets/rabbitmq-ha.age;
    group = "home-automation-secrets";
    mode = "440";
  };

  users.groups.home-automation-secrets = { };

  systemd.services.home-automation = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "rabbitmq.target" ];
    description = "Home automation";
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      ExecStart = "${homeAutomationPackage}/bin/home-automation";
      SupplementaryGroups = "home-automation-secrets";
    };
  };
}
