{ pkgs, config, lib, ... }: {
  systemd.services.kube-controller-manager = lib.mkIf config.ramona.kubernetes.is-control-plane {
    description = "kubernetes controller manager";
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
        ${pkgs.kubernetes}/bin/kube-controller-manager \
            --allocate-node-cidrs=true \
            --logging-format=json \
            --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf \
            --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf \
            --bind-address=0.0.0.0 \
            --client-ca-file=/etc/kubernetes/pki/ca.crt \
            --cluster-cidr=${config.ramona.kubernetes.pod-cidr} \
            --cluster-name=kubernetes \
            --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt \
            --cluster-signing-key-file=/etc/kubernetes/pki/ca.key \
            --controllers=*,bootstrapsigner,tokencleaner \
            --kubeconfig=/etc/kubernetes/controller-manager.conf \
            --leader-elect=true \
            --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt \
            --root-ca-file=/etc/kubernetes/pki/ca.crt \
            --service-account-private-key-file=/etc/kubernetes/pki/sa.key \
            --service-cluster-ip-range=${config.ramona.kubernetes.service-cidr} \
            --use-service-account-credentials=true
      '';
    };
  };
}
