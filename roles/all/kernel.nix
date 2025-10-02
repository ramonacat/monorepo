{
  lib,
  pkgs,
  ...
}: {
  config = {
    boot = {
      kernelParams = [
        # this is needed for iotop
        "delayacct"
      ];
      kernelPackages = lib.mkOverride 500 pkgs.linuxPackages_latest;
      kernel = {
        features.debug = true;
        sysctl."kernel.sysrq" = 1;
      };
    };
  };
}
