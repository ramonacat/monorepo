_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private

    ./hardware.nix
    ./networking.nix
    ./snmpd.nix
    ./transmission.nix
  ];
  config = {
    ramona = {
      machine.location = "pl1";
      # TODO this is kinda wrong, this machine should live on its own (perhaps virtual) subnet, instead of depending on host's network, also we don't route that subnnet
      home-subnet = "192.168.2.0/24";
    };
  };
}
