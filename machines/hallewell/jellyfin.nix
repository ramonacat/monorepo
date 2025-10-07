{pkgs, ...}: {
  config = {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-ocl
        intel-media-driver
        intel-compute-runtime-legacy1
      ];
    };
  };
}
