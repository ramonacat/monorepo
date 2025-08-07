_: {
  imports =
    [
      ../../modules/machine-kind.nix
    ]
    ++ (import ../../libs/nix/nix-files-from-dir.nix ./.);
  config = {
    ramona.machine = {
      type = "server";
      hasPublicIP = true;
    };
  };
}
