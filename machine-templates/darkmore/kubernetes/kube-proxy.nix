{
  pkgs,
  config,
  ...
}:
{
  systemd.services.kube-proxy = {
    description = "kubernetes proxy";
    wantedBy = [ "kubernetes.target" ];
    unitConfig = {
      StartLimitIntervalSec = 5;
    };
    path = with pkgs; [
      iptables
      nftables
      conntrack-tools
    ];
    serviceConfig =
      let
        kube-proxy-config = pkgs.writeText "kube-proxy.conf" ''
          apiVersion: kubeproxy.config.k8s.io/v1alpha1
          bindAddress: 0.0.0.0
          bindAddressHardFail: false
          clientConnection:
            kubeconfig: /etc/kubernetes/kube-proxy.conf
          clusterCIDR: ${config.ramona.kubernetes.pod-cidr}
          kind: KubeProxyConfiguration
          logging:
            format: 'json'
          metricsBindAddress: "0.0.0.0:10249"
        '';
      in
      {
        RestartSec = "10s";
        Restart = "on-failure";
        ExecStart = ''
          ${pkgs.kubernetes}/bin/kube-proxy \
              --config=${kube-proxy-config} \
              --hostname-override=${config.networking.hostName}
        '';
      };
  };
}
