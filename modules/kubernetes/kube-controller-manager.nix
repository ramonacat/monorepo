{
  pkgs,
  config,
  lib,
  ...
}:
{
  systemd.services.kube-controller-manager = lib.mkIf config.ramona.kubernetes.is-control-plane {
    description = "kubernetes controller manager";
    wantedBy = [ "kubernetes.target" ];
    after = [ "network.target" ];
    unitConfig = {
      StartLimitIntervalSec = 5;
    };
    serviceConfig =
      let
        klib = import ./_lib.nix { inherit lib config; };
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
        ExecStart = ''
          ${pkgs.kubernetes}/bin/kube-controller-manager \
              --allocate-node-cidrs=true \
              --logging-format=json \
              --authentication-kubeconfig=${klib.kubeconfig-path "default-controller-manager"} \
              --authorization-kubeconfig=${klib.kubeconfig-path "default-controller-manager"} \
              --bind-address=0.0.0.0 \
              --client-ca-file=${
                config.ramona.ca-certificates."${config.ramona.kubernetes.cluster-name}".cluster
              } \
              --cluster-cidr=${config.ramona.kubernetes.pod-cidr} \
              --cluster-name=kubernetes \
              --controllers=*,bootstrapsigner,tokencleaner \
              --kubeconfig=${klib.kubeconfig-path "default-controller-manager"} \
              --leader-elect=true \
              --requestheader-client-ca-file=${
                config.ramona.ca-certificates."${config.ramona.kubernetes.cluster-name}".front-proxy
              } \
              --root-ca-file=${
                config.ramona.ca-certificates."${config.ramona.kubernetes.cluster-name}".cluster
              } \
              --service-account-private-key-file=${config.ramona.kubernetes.service-account-key.key} \
              --service-cluster-ip-range=${config.ramona.kubernetes.service-cidr} \
              --use-service-account-credentials=true
        '';
      };
  };
}
