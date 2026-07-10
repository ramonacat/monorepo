{ config, ... }: {
  imports = [
    ../../modules/machine-kind.nix

    ./pam.nix
  ];
  config = {
    ramona.machine = {
      type = "server";
      hasPublicIP = false;
      roles = [ "private" ];
      tailscale-tags = [
        "tag:server"
        "tag:server-private"
        "tag:server-private-${config.ramona.machine.location}"
      ];
    };
  };
}
