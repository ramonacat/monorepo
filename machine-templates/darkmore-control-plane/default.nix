{ lib, ... }: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public
    ../../roles/tailscale-nginx

    ./networking.nix
    ./kubernetes.nix
  ];
  options = {
    ramona.darkmore-control-plane = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            id = lib.mkOption { type = int; };
            total-count = lib.mkOption { type = int; };
          };
        };
    };
  };
}
