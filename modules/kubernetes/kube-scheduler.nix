{
  pkgs,
  config,
  lib,
  ...
}:
{
  systemd.services.kube-scheduler = lib.mkIf config.ramona.kubernetes.is-control-plane {
    description = "kubernetes scheduler";
    wantedBy = [ "kubernetes.target" ];
    after = [ "network.target" ];
    unitConfig = {
      StartLimitIntervalSec = 5;
    };
    serviceConfig =
      let
        klib = import ./_lib.nix { inherit config lib; };
      in
      {
        RestartSec = "10s";
        Restart = "on-failure";
        User = "kubernetes";
        Group = "kubernetes";
        CPUSchedulingPolicy = "rr";
        CPUSchedulingPriority = 49;
        IOSchedulingPriority = 1;
        Nice = -10;
        ExecStart =
          let
            kubeconfig = klib.kubeconfig-path "default-scheduler";
          in
          ''
            ${pkgs.kubernetes}/bin/kube-scheduler \
                --authentication-kubeconfig=${kubeconfig} \
                --authorization-kubeconfig=${kubeconfig} \
                --bind-address=0.0.0.0 \
                --kubeconfig=${kubeconfig} \
                --leader-elect=true \
                --logging-format=json
          '';
      };
  };
}
