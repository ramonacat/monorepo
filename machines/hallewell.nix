{ config, pkgs, lib, ... }:
{
  config = {
    fileSystems."/mnt/nas" =
      {
        device = "10.69.10.139:/mnt/data0/data";
        fsType = "nfs";
      };

    services.syncthing = {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = {
          "phone" = { "id" = "VZK66I4-WTFCOWJ-B7LH6QV-FDQFTSH-FTBWTIH-UUDRUOR-SNIZBPS-AMRDBAU"; };
        };

        folders = {
          "shared" = {
            path = "/mnt/nas/shared/";
            devices = [ "phone" ];
          };
        };
      };
    };

    # For syncthing
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
