_: {
  config = {
    services.bcachefs.autoScrub = let
      paths = import ../../data/paths.nix;
    in {
      enable = true;
      fileSystems = [paths.hallewell.nas-root];
    };
    systemd = {
      services.bcachefs-disable-rebalance = {
        script = "echo -n 0 > /sys/fs/bcachefs/8f552709-24e3-4387-8183-23878c94d00b/options/rebalance_enabled";
        serviceConfig = {
          Type = "oneshot";
        };
      };

      services.bcachefs-enable-rebalance = {
        script = "echo -n 1 > /sys/fs/bcachefs/8f552709-24e3-4387-8183-23878c94d00b/options/rebalance_enabled";
        serviceConfig = {
          Type = "oneshot";
        };
      };

      timers.bcachefs-enable-rebalance = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 10:00:00";
          Persistent = true;
          Unit = "bcachefs-enable-rebalance.service";
        };
      };

      timers.bcachefs-disable-rebalance = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 21:00:00";
          Persistent = true;
          Unit = "bcachefs-disable-rebalance.service";
        };
      };
    };
  };
}
