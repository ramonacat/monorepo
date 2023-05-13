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

      devices = {
        "phone" = { "id" = "VZK66I4-WTFCOWJ-B7LH6QV-FDQFTSH-FTBWTIH-UUDRUOR-SNIZBPS-AMRDBAU"; };
        "hallewell" = { "id" = "BKZEEQS-2VYH2DZ-FRANPJH-I4WOFMZ-DO3N7AJ-XSK7J3D-P57XCTW-S66ZEQY"; };
      };

      folders = {
        "shared" = {
          path = "/mnt/nas/shared/";
          devices = [ "phone" "hallewell" ];
        };
      };
    };

    # For syncthing
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
