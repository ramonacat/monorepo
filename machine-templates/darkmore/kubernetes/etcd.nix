{ config, lib, ... }: {
  config = {
    services.etcd = lib.mkIf config.ramona.kubernetes.is-control-plane {
      enable = true;
      advertiseClientUrls = [ "https://${config.ramona.kubernetes.ip}:2379" ];
      certFile = "/etc/kubernetes/pki/etcd/server.crt";
      clientCertAuth = true;
      initialAdvertisePeerUrls = [ "https://${config.ramona.kubernetes.ip}:2380" ];
      initialCluster = map (host: "${host.hostname}=https://${host.ip}:2380") (
        builtins.filter (x: x.is-control-plane) config.ramona.kubernetes.all-nodes
      );
      keyFile = "/etc/kubernetes/pki/etcd/server.key";
      listenClientUrls = [
        "https://127.0.0.1:2379"
        "https://${config.ramona.kubernetes.ip}:2379"
      ];
      listenPeerUrls = [ "https://${config.ramona.kubernetes.ip}:2380" ];
      peerCertFile = "/etc/kubernetes/pki/etcd/peer.crt";
      peerClientCertAuth = true;
      peerKeyFile = "/etc/kubernetes/pki/etcd/peer.key";
      peerTrustedCaFile = "/etc/kubernetes/pki/etcd/ca.crt";
      trustedCaFile = "/etc/kubernetes/pki/etcd/ca.crt";
      extraConf = {
        FEATURE_GATES = "InitialCorruptCheck=true";
        LISTEN_METRICS_URLS = "http://0.0.0.0:2381";
        SNAPSHOT_COUNT = "10000";
        WATCH_PROGRESS_NOTIFY_INTERVAL = "5s";
      };
    };
  };
}
