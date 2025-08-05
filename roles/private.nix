_: {
  imports = (import ../libs/nix/nix-files-from-dir.nix ./private) ++ [../modules/machine-kind.nix];
  config = {
    ramona.machine = {
      type = "server";
      hasPublicIP = false;
    };
  };
}
