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

      # settings = {
      devices = {
        "phone" = { "id" = "VZK66I4-WTFCOWJ-B7LH6QV-FDQFTSH-FTBWTIH-UUDRUOR-SNIZBPS-AMRDBAU"; };
        "hallewell" = { "id" = "BKZEEQS-2VYH2DZ-FRANPJH-I4WOFMZ-DO3N7AJ-XSK7J3D-P57XCTW-S66ZEQY"; };
        "tablet" = { "id" = "RRUE6ZX-AXPN4HG-DUFIBV5-A4A3CTI-KQ3QO25-7WTBNWM-OUMDZUA-NLFBVQK"; };
      };

      folders = {
        "shared" = {
          path = "/mnt/nas/shared/";
          devices = [ "phone" "hallewell" "tablet" ];
        };
      };
      # };
    };

    # For syncthing
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];

    services.tailscale.enable = true;

    services.zoneminder = {
      enable = true;
      hostname = "localhost";
      openFirewall = true;
      database.createLocally = true;
      database.username = "zoneminder";
      cameras = 3;
    };
  };
}
