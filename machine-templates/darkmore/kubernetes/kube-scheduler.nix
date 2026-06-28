{ pkgs, config, ... }: {
  systemd.services.kube-scheduler = {
    description = "kubernetes scheduler";
    wantedBy = [ "kubernetes.target" ];
    unitConfig = {
      StartLimitIntervalSec = 5;
    };
    serviceConfig = {
      RestartSec = "10s";
      Restart = "on-failure";
      User = "kubernetes";
      Group = "kubernetes";
      ExecStart = ''
        ${pkgs.kubernetes}/bin/kube-scheduler \
            --authentication-kubeconfig=/etc/kubernetes/scheduler.conf \
            --authorization-kubeconfig=/etc/kubernetes/scheduler.conf \
            --bind-address=0.0.0.0 \
            --kubeconfig=/etc/kubernetes/scheduler.conf \
            --leader-elect=true \
            --logging-format=json
      '';
    };
  };
}
