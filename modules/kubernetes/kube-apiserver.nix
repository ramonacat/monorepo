{
  pkgs,
  config,
  lib,
  ...
}:
{
  config =
    let
      klib = import ./_lib.nix { inherit lib config; };
    in
    {
      systemd.services.kube-apiserver = lib.mkIf config.ramona.kubernetes.is-control-plane {
        description = "kubernetes apiserver service";
        wantedBy = [ "kubernetes.target" ];
        after = [ "network.target" ];
        unitConfig = {
          StartLimitIntervalSec = 5;
        };
        serviceConfig = {
          CPUSchedulingPolicy = "rr";
          CPUSchedulingPriority = 49;
          IOSchedulingPriority = 1;
          Nice = -10;
          ExecStart =
            let
              cluster-cas = config.ramona.ca-certificates."${config.ramona.kubernetes.cluster-name}";
            in
            ''
              ${pkgs.kubernetes}/bin/kube-apiserver \
                  --advertise-address=${config.ramona.kubernetes.ip} \
                  --allow-privileged=true \
                  --authorization-mode=Node,RBAC \
                  --client-ca-file=${cluster-cas.cluster} \
                  --enable-admission-plugins=NodeRestriction \
                  --enable-bootstrap-token-auth=true \
                  --etcd-cafile=${cluster-cas.etcd} \
                  --etcd-certfile=${klib.certificate-path "apiserver-etcd-client" "crt"} \
                  --etcd-keyfile=${klib.certificate-path "apiserver-etcd-client" "key"} \
                  --etcd-servers=https://127.0.0.1:2379 \
                  --kubelet-client-certificate=${klib.certificate-path "apiserver-kubelet-client" "crt"} \
                  --kubelet-client-key=${klib.certificate-path "apiserver-kubelet-client" "key"} \
                  --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
                  --proxy-client-cert-file=${klib.certificate-path "front-proxy-client" "crt"} \
                  --proxy-client-key-file=${klib.certificate-path "front-proxy-client" "key"} \
                  --requestheader-allowed-names=front-proxy-client \
                  --requestheader-client-ca-file=${cluster-cas.front-proxy} \
                  --requestheader-extra-headers-prefix=X-Remote-Extra- \
                  --requestheader-group-headers=X-Remote-Group \
                  --requestheader-username-headers=X-Remote-User \
                  --secure-port=6443 \
                  --service-account-issuer=https://kubernetes.default.svc.cluster.local \
                  --service-account-key-file=${config.ramona.kubernetes.service-account-key.pub} \
                  --logging-format=json \
                  --service-account-signing-key-file=${config.ramona.kubernetes.service-account-key.key} \
                  --service-cluster-ip-range=${config.ramona.kubernetes.service-cidr} \
                  --tls-cert-file=${klib.certificate-path "apiserver" "crt"} \
                  --tls-private-key-file=${klib.certificate-path "apiserver" "key"}
            '';
          User = "kubernetes";
          Group = "kubernetes";
          AmbientCapabilities = "cap_net_bind_service";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
