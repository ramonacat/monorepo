_: {
  config = {
    services.bcachefs.autoScrub = let
      paths = import ../../data/paths.nix;
    in {
      enable = true;
      fileSystems = [paths.hallewell.nas-root];
      interval = "*-*-01 02:00:00";
    };
    systemd = {
      services.bcachefs-disable-reconcile = {
        script = "echo -n 0 > /sys/fs/bcachefs/8f552709-24e3-4387-8183-23878c94d00b/options/reconcile_enabled";
        serviceConfig = {
          Type = "oneshot";
        };
      };

      services.bcachefs-enable-reconcile = {
        script = "echo -n 1 > /sys/fs/bcachefs/8f552709-24e3-4387-8183-23878c94d00b/options/reconcile_enabled";
        serviceConfig = {
          Type = "oneshot";
        };
      };

      timers.bcachefs-enable-reconcile = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 10:00:00";
          Persistent = true;
          Unit = "bcachefs-enable-reconcile.service";
        };
      };

      timers.bcachefs-disable-reconcile = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 21:00:00";
          Persistent = true;
          Unit = "bcachefs-disable-reconcile.service";
        };
      };
    };
  };
}
