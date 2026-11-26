_: {
  imports = [
    ../../modules/kubernetes-christanti

    ./hardware.nix
    ./networking.nix
  ];
  config = {
    ramona = {
      machine.location = "home";
      home-subnet = "10.64.0.0/28";

      kubernetes = {
        ip = "10.64.0.10";
        is-control-plane = true;
        host-pod-cidr = "10.65.0.0/24";
      };
    };
  };
}
