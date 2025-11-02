{pkgs, ...}: {
  imports = [
    ./backup.nix
  ];
  config = {
    services.jellyfin = let
      paths = import ../../../data/paths.nix;
    in {
      enable = true;
      openFirewall = true;
      dataDir = "${paths.hallewell.jellyfin}/";
      configDir = "${paths.hallewell.jellyfin}/config";
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
