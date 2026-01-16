{pkgs, ...}: {
  imports = [
    ./backup.nix
  ];
  config = let
    paths = import ../../../data/paths.nix;
  in {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
      dataDir = "${paths.hallewell.jellyfin}/";
      configDir = "${paths.hallewell.jellyfin}/config";
    };

    systemd.services.jellyfin = {
      environment.LIBVA_DRIVER_NAME = "iHD";
      serviceConfig.ReadWritePaths = ["${paths.hallewell.nas-share}/Media"];
    };

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
