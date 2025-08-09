_: {
  imports = [
    ../../roles/all
    ../../roles/installed
    ../../roles/private
    ../../roles/server-private

    ../../users/ramona/installed
    ../../users/root/installed

    ./hardware.nix
    ./networking.nix
    ./transmission.nix
  ];
}
