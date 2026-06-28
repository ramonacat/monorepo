{
  pkgs,
  config,
  lib,
  ...
}:
{
  systemd.services.kube-apiserver = lib.mkIf config.ramona.kubernetes.is-control-plane {
    description = "kubernetes apiserver service";
    wantedBy = [ "kubernetes.target" ];
    unitConfig = {
      StartLimitIntervalSec = 5;
    };
    serviceConfig = {
      ExecStart = ''
        ${pkgs.kubernetes}/bin/kube-apiserver \
            --advertise-address=${config.ramona.kubernetes.ip} \
            --allow-privileged=true \
            --authorization-mode=Node,RBAC \
            --client-ca-file=/etc/kubernetes/pki/ca.crt \
            --enable-admission-plugins=NodeRestriction \
            --enable-bootstrap-token-auth=true \
            --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt \
            --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt \
            --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key \
            --etcd-servers=https://127.0.0.1:2379 \
            --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
            --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
            --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
            --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt \
            --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key \
            --requestheader-allowed-names=front-proxy-client \
            --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt \
            --requestheader-extra-headers-prefix=X-Remote-Extra- \
            --requestheader-group-headers=X-Remote-Group \
            --requestheader-username-headers=X-Remote-User \
            --secure-port=6443 \
            --service-account-issuer=https://kubernetes.default.svc.cluster.local \
            --service-account-key-file=/etc/kubernetes/pki/sa.pub \
            --logging-format=json \
            --service-account-signing-key-file=/etc/kubernetes/pki/sa.key \
            --service-cluster-ip-range=${config.ramona.kubernetes.service-cidr} \
            --tls-cert-file=/etc/kubernetes/pki/apiserver.crt \
            --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
      '';
      User = "kubernetes";
      Group = "kubernetes";
      AmbientCapabilities = "cap_net_bind_service";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
