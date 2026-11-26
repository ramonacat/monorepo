_: {
  imports = [
    ../../modules/kubernetes-christanti

    ./hardware.nix
    ./networking.nix
  ];
  config = {
    ramona = {
      machine.location = "home";
      home-subnet = "10.64.0.16/32";

      kubernetes = {
        ip = "10.64.0.16";
        is-control-plane = true;
        host-pod-cidr = "10.65.1.0/24";
      };
    };
  };
}
