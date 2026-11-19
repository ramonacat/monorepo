_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private
    ../../modules/kubernetes

    ./hardware.nix
    ./networking.nix
  ];
  config = {
    ramona = {
      machine.location = "home";
      home-subnet = "10.64.0.0/24";

      kubernetes = {
        cluster-name = "christanti";
        ip = "10.64.0.10";
        internal-apiserver-ip = "10.80.0.1";

        hostname = "depraysie";
        is-control-plane = true;
        cluster-dns-ip = "10.80.0.10";
        service-cidr = "10.80.0.0/12";
        pod-cidr = "10.65.0.0/16";

        host-pod-cidr = "10.65.0.0/24";

        all-nodes = [
          {
            ip = "10.64.0.10";
            hostname = "depraysie";
            is-control-plane = true;
          }
        ];
      };
    };

    # allow OSPF and BFD from peer routers
    networking.firewall.extraInputRules = ''
      ip saddr 10.64.0.0/11 ip protocol ospfigp accept
      ip saddr 10.64.0.0/11 udp dport { 3784, 3785, 4784 } accept
    '';
  };
}
