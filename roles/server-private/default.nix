_: {
  imports = [
    ../../modules/machine-kind.nix

    ./pam.nix
  ];
  config = {
    ramona.machine = {
      type = "server";
      hasPublicIP = false;
    };
    ramona.roles = ["private"];
  };
}
