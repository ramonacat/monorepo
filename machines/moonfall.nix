{ config, pkgs, lib, ... }:
{
  config = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "rebuild-all-machines" ''
        #!/usr/bin/env bash

        set -euo pipefail
        set -x

        sudo nixos-rebuild switch --flake .#moonfall -L --show-trace

        nixos-rebuild --target-host ramona@ananas --use-remote-sudo switch --flake .#ananas -L --show-trace
        nixos-rebuild --target-host ramona@hallewell --use-remote-sudo switch --flake .#hallewell -L --show-trace
        nixos-rebuild --target-host ramona@shadowmend --use-remote-sudo switch --flake .#shadowmend -L --show-trace
        nixos-rebuild --target-host ramona@angelsin --use-remote-sudo switch --flake .#angelsin -L --show-trace
      '')
    ];
  };
}
