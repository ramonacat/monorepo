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
      machine.location = "ovh-gra1";
      home-subnet = "10.64.0.18/32";

      kubernetes = {
        ip = "10.64.0.18";
        is-control-plane = false;
        host-pod-cidr = "10.65.3.0/24";
      };
    };
  };
}
