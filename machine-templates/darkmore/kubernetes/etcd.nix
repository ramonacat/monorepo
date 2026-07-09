{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    let
      cert = "/var/ramona/kubernetes/etcd.crt";
      cert-key = "/var/ramona/kubernetes/etcd.key";
    in
    {
      ramona.vault-agent.templates = lib.mkIf config.ramona.kubernetes.is-control-plane [
        {
          contents = ''
            {{- with pkiCert "pki-kubernetes-darkmore/issue/hosts" "common_name=${config.networking.hostName}" "alt_names=localhost" "ip_sans=${config.ramona.kubernetes.ip},127.0.0.1" "ttl=24h" -}}
            {{ .Cert }}{{ .CA }}{{ .Key }}
            {{ .Cert | writeToFile "${cert}" "etcd" "etcd" "0644" }}
            {{ .Key | writeToFile "${cert-key}" "etcd" "etcd" "0400" }}
            {{- end -}}
          '';
          destination = "/var/ramona/kubernetes/etcd-bundle";
        }
      ];
      services.etcd = lib.mkIf config.ramona.kubernetes.is-control-plane {
        enable = true;
        clientCertAuth = true;
        certFile = cert;
        keyFile = cert-key;
        peerCertFile = cert;
        peerClientCertAuth = true;
        peerKeyFile = cert-key;

        trustedCaFile = pkgs.writeText "cert-bundle" (
          (builtins.readFile ../../../certificates/ca.crt)
          + "\n"
          + (builtins.readFile ../../../certificates/ca-kubernetes-darkmore.crt)
        );
        # TODO perhaps a separate CA just for etcd?
        peerTrustedCaFile = ../../../certificates/ca-kubernetes-darkmore.crt;

        advertiseClientUrls = [ "https://${config.ramona.kubernetes.ip}:2379" ];
        initialAdvertisePeerUrls = [ "https://${config.ramona.kubernetes.ip}:2380" ];
        initialCluster = map (host: "${host.hostname}=https://${host.ip}:2380") (
          builtins.filter (x: x.is-control-plane) config.ramona.kubernetes.all-nodes
        );
        listenClientUrls = [
          "https://127.0.0.1:2379"
          "https://${config.ramona.kubernetes.ip}:2379"
        ];
        listenPeerUrls = [ "https://${config.ramona.kubernetes.ip}:2380" ];
        extraConf = {
          FEATURE_GATES = "InitialCorruptCheck=true";
          LISTEN_METRICS_URLS = "http://0.0.0.0:2381";
          SNAPSHOT_COUNT = "10000";
          WATCH_PROGRESS_NOTIFY_INTERVAL = "5s";
        };
      };

      services.restic.backups.etcd =
        let
          backupPath = "/var/ramona/etcd-backup/";
        in
        lib.mkIf config.ramona.kubernetes.is-control-plane (
          import ../../../libs/nix/mk-restic-config.nix { inherit config pkgs; } {
            timerConfig = {
              OnCalendar = "*-*-* *:00:00";
              RandomizedDelaySec = "30min";
            };
            backupPrepareCommand = ''
              mkdir -p "${backupPath}"
              ${pkgs.etcd}/bin/etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key snapshot save ${backupPath}/snapshot.db
            '';
            backupCleanupCommand = ''
              rm -r ${backupPath} || true
            '';
            paths = [
              backupPath
            ];
          }
        );
    };
}
