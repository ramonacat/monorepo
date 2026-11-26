{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    let
      klib = import ./_lib.nix { inherit lib config; };
    in
    {
      services.etcd = lib.mkIf config.ramona.kubernetes.is-control-plane {
        enable = true;
        clientCertAuth = true;

        certFile = klib.certificate-path "etcd" "crt";
        keyFile = klib.certificate-path "etcd" "key";

        peerCertFile = klib.certificate-path "etcd-peer" "crt";
        peerKeyFile = klib.certificate-path "etcd-peer" "key";

        trustedCaFile = config.ramona.ca-certificates."${config.ramona.kubernetes.cluster-name}".etcd;

        peerClientCertAuth = true;

        advertiseClientUrls = lib.mkForce [ "https://${config.ramona.kubernetes.ip}:2379" ];
        initialAdvertisePeerUrls = [ "https://${config.ramona.kubernetes.ip}:2380" ];
        initialCluster = map (host: "${host.hostname}=https://${host.ip}:2380") (
          builtins.filter (x: x.is-control-plane) config.ramona.kubernetes.all-nodes
        );
        listenClientUrls = lib.mkForce [
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
      systemd.services.etcd.serviceConfig = lib.mkIf config.ramona.kubernetes.is-control-plane {
        CPUSchedulingPolicy = "rr";
        CPUSchedulingPriority = 49;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 0;
        Nice = -10;
      };

      services.restic.backups.etcd =
        let
          backupPath = "/var/ramona/etcd-backup/";
        in
        lib.mkIf config.ramona.kubernetes.is-control-plane (
          import ../../libs/nix/mk-restic-config.nix { inherit config pkgs; } {
            timerConfig = {
              OnCalendar = "*-*-* *:00:00";
              RandomizedDelaySec = "30min";
            };
            backupPrepareCommand = ''
              mkdir -p "${backupPath}"
              ${pkgs.etcd}/bin/etcdctl --cacert=${
                config.ramona.ca-certificates."${config.ramona.kubernetes.cluster-name}".etcd
              } --cert=${klib.certificate-path "etcd-peer" "crt"} --key=${klib.certificate-path "etcd-peer" "key"} snapshot save ${backupPath}/snapshot.db
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
