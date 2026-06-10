{ lib, ... }: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ./networking.nix
  ];
  options = {
    ramona.darkmore-control-plane = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            id = lib.mkOption { type = int; };
          };
        };
    };
  };
}
