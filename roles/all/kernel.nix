{
  lib,
  pkgs,
  config,
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
    environment = {
      systemPackages = let
        inherit (config.boot.kernelPackages) kernel;
      in [
        (pkgs.writeShellApplication
          {
            name = "decode-kernel-stacktrace";
            runtimeInputs = with pkgs; [stdenv gcc util-linux];
            text = ''
              exec ${kernel.dev}/lib/modules/${kernel.modDirVersion}/source/scripts/decode_stacktrace.sh \
                  ${kernel.dev}/vmlinux \
                  /build/source/build/.. \
                  /run/booted-system/kernel-modules/lib/modules/${kernel.modDirVersion} \
            '';
          })
      ];
    };
  };
}
