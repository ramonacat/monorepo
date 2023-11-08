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
      user = "ramona";

      dataDir = "/home/ramona/.syncthing-data";
      configDir = "/home/ramona/.config/syncthing";

      settings = {

        devices = {
          "phone" = { "id" = "VZK66I4-WTFCOWJ-B7LH6QV-FDQFTSH-FTBWTIH-UUDRUOR-SNIZBPS-AMRDBAU"; };
          "hallewell" = { "id" = "BKZEEQS-2VYH2DZ-FRANPJH-I4WOFMZ-DO3N7AJ-XSK7J3D-P57XCTW-S66ZEQY"; };
          "tablet" = { "id" = "RRUE6ZX-AXPN4HG-DUFIBV5-A4A3CTI-KQ3QO25-7WTBNWM-OUMDZUA-NLFBVQK"; };
          "angelsin" = { "id" = "23QKYLN-5QFUF4B-EJGKEJ7-GBUCSZF-HY65NGW-GDUJAE3-5TE5IHB-2FWC4QU"; };
        };

        folders = {
          "shared" = {
            path = "/home/ramona/shared/";
            devices = [ "phone" "hallewell" "tablet" "angelsin" ];
          };

          "Music" = {
            path = "/mnt/nas/Music/";
            devices = [ "tablet" ];
          };
        };
      };
    };

    # For syncthing
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
