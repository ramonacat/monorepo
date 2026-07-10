{ config, ... }: {
  imports = [
    ../../modules/machine-kind.nix
    ./restic-secrets.nix
  ];
  config = {
    ramona.machine = {
      type = "server";
      hasPublicIP = true;
      roles = [ "server-public" ];
      tailscale-tags = [
        "tag:server"
        "tag:server-public"
        "tag:server-public-${config.ramona.machine.location}"
      ];
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "ramona@luczkiewi.cz";
    };
  };
}
