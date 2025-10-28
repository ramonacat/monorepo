# this is a workaround for https://github.com/NixOS/nixos-hardware/issues/1581
{config, ...}: {
  config = {
    hardware.framework = {
      enableKmod = false;
    };

    boot = {
      kernelModules = ["cros_ec" "cros_ec_lpcs"];
      extraModulePackages = with config.boot.kernelPackages; [
        framework-laptop-kmod
      ];
    };
  };
}
