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

    systemd.oomd = {
      enableRootSlice = lib.mkForce false;
      enableSystemSlice = lib.mkForce false;
      enableUserSlices = lib.mkForce false;
      settings = {
        OOM = {
          SwapUsedLimit = "70%";
          DefaultMemoryPressureDurationSec = "30";
        };
      };
    };

    systemd.slices."kubepods".sliceConfig = {
      ManagedOOMSwap = "kill";
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "40%";
    };
    systemd.slices."kubepods-burstable".sliceConfig = {
      ManagedOOMSwap = "kill";
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMPreference = "avoid";
      ManagedOOMMemoryPressureLimit = "80%";
    };
  };
}
