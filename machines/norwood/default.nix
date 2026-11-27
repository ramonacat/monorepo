_: {
  imports = [
    ../../roles/server-public

    ../../modules/kubernetes-christanti

    ./disko.nix
    ./hardware.nix
    ./networking.nix
  ];
  config = {
    ramona = {
      machine.location = "contabo-eu";
      home-subnet = "10.64.0.17/32";

      kubernetes = {
        ip = "10.64.0.17";
        is-control-plane = true;
        host-pod-cidr = "10.65.2.0/24";
      };
    };
    services.etcd.initialClusterState = "existing";
  };
}
