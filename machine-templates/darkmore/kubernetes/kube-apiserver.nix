{
  pkgs,
  config,
  lib,
  ...
}:
{
  config =
    let
      cert = "/var/ramona/kubernetes/apiserver-client-etcd.crt";
      cert-key = "/var/ramona/kubernetes/apiserver-client-etcd.key";
    in
    {
      ramona.vault-agent.templates = lib.mkIf config.ramona.kubernetes.is-control-plane [

        {
          contents = ''
            {{- with pkiCert "pki-kubernetes-darkmore/issue/hosts" "common_name=kube-apiserver-etcd-client" "alt_names=localhost" "ip_sans=${config.ramona.kubernetes.ip},127.0.0.1" "ttl=24h" -}}
            {{ .Cert }}{{ .CA }}{{ .Key }}
            {{ .Cert | writeToFile "${cert}" "kubernetes" "kubernetes" "0644" }}
            {{ .Key | writeToFile "${cert-key}" "kubernetes" "kubernetes" "0400" }}
            {{- end -}}
          '';
          destination = "/var/ramona/kubernetes/apiserver-client-etcd-bundle";
        }
      ];
      systemd.services.kube-apiserver = lib.mkIf config.ramona.kubernetes.is-control-plane (
        let
          cert-bundle = pkgs.writeText "cert-bundle" (
            (builtins.readFile ../../../certificates/ca.crt)
            + "\n"
            + (builtins.readFile ../../../certificates/ca-kubernetes-darkmore.crt)
          );
        in
        {
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
                  --etcd-cafile=${cert-bundle} \
                  --etcd-certfile=${cert} \
                  --etcd-keyfile=${cert-key} \
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
        }
      );
    };
}
