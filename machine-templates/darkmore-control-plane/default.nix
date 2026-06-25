{ lib, ... }: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ./kubernetes
    ./networking.nix
  ];
  options = {
    ramona.darkmore-control-plane = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            ip = lib.mkOption { type = str; };
            hostname = lib.mkOption { type = str; };
            all-nodes = lib.mkOption {
              type = listOf (submodule {
                options = {
                  ip = lib.mkOption { type = str; };
                  hostname = lib.mkOption { type = str; };
                };
              });
            };
          };
        };
    };
  };
  config = {
    ramona.machine.tailscale-tags = [
      "tag:kubernetes-darkmore"
      "tag:kubernetes-darkmore-control-plane"
    ];

    services.prometheus.exporters.node.enable = lib.mkForce false;
    services.prometheus.exporters.smartctl.enable = lib.mkForce false;
  };
}
