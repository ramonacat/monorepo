_: {
  imports = [
    ../../modules/machine-kind.nix
    ./restic-secrets.nix
  ];
  config = {
    ramona.machine = {
      type = "server";
      hasPublicIP = true;
    };
  };
}
