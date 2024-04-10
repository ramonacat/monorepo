{pkgs, ...}: {
  config = {
    services.ramona.ras = {
      enable = true;
      dataFile = "/mnt/nas3/data/shared/todos.json";
    };

    networking.firewall.allowedTCPPorts = [8438];

    systemd.services.rat-monitoring-maintenance = {
      serviceConfig = {
        Type = "oneshot";
        User = "ramona";
        ExecStart = "${pkgs.ramona.rat}/bin/rat maintenance monitoring";
      };
    };

    systemd.timers.rat-monitoring-maintenance = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 00/6:00:00";
        RandomizedDelaySec = "3h";
        Unit = "rat-monitoring-maintenance.service";
      };
    };
  };
}
