_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private
    ../../modules/kubernetes

    ./disks.nix
  ];
  config = {
    ramona = {
      kubernetes = {
        cluster-name = "christanti";
        internal-apiserver-ip = "10.80.0.1";
        cluster-dns-ip = "10.80.0.10";
        service-cidr = "10.80.0.0/12";
        pod-cidr = "10.65.0.0/16";

        all-nodes = [
          {
            ip = "10.64.0.10";
            hostname = "depraysie";
            is-control-plane = true;
          }
          {
            ip = "10.64.0.16";
            hostname = "killian";
            is-control-plane = true;
          }
        ];
      };
    };

    services.etcd.extraConf = {
      "HEARTBEAT_INTERVAL" = "150";
      "ELECTION_TIMEOUT" = "1500";
    };

    # allow OSPF and BFD from peer routers
    # allow darkmore to talk with the apiserver (for argocd)
    networking.firewall.extraInputRules = ''
      ip saddr 10.64.0.0/24 accept

      ip saddr 10.64.0.0/11 ip protocol ospfigp accept
      ip saddr 10.64.0.0/11 udp dport { 3784, 3785, 4784 } accept

      ip saddr 10.0.0.0/11 tcp dport { 6443 } accept
    '';
  };
}
