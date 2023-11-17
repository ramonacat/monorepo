{ homeAutomationPackage }:
{ config, pkgs, lib, ... }:
{
      systemd.services.home-automation = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "rabbitmq.target" ];
      description = "Home automation";
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${homeAutomationPackage}/bin/home-automation";
      };
    };
}
