_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private

    ./hardware.nix
    ./networking.nix
    ./transmission.nix
  ];
  config = {
    ramona.machine.location = "pl1";
  };
}
