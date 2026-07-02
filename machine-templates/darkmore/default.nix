{ lib, config, ... }: {
  imports = [
    ../../roles/all
    ../../roles/hetzner-cloud
    ../../roles/installed
    ../../roles/server-public

    ./kubernetes
  ];
  config = {
    ramona.machine.tailscale-tags = [
      "tag:kubernetes-darkmore"
    ]
    ++ (
      if config.ramona.kubernetes.is-control-plane then
        [ "tag:kubernetes-darkmore-control-plane" ]
      else
        [ ]
    );

    services.prometheus.exporters = {
      node.enable = lib.mkForce false;
      smartctl.enable = lib.mkForce false;
      systemd.enable = lib.mkForce false;
    };
  };
}
