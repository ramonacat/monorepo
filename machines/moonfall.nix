{ config, pkgs, lib, ... }:
{
  config = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "rebuild-all-machines" ''
        #!/usr/bin/env bash

        set -euo pipefail
        set -x

        sudo nixos-rebuild switch --flake .#moonfall -L --show-trace

        nixos-rebuild --target-host ramona@ananas --use-remote-sudo switch --flake .#ananas -L --show-trace
        nixos-rebuild --target-host ramona@hallewell --use-remote-sudo switch --flake .#hallewell -L --show-trace
        nixos-rebuild --target-host ramona@shadowmend --use-remote-sudo switch --flake .#shadowmend -L --show-trace
        nixos-rebuild --target-host ramona@caligari --use-remote-sudo switch --flake .#caligari -L --show-trace
        nixos-rebuild --target-host ramona@angelsin --use-remote-sudo switch --flake .#angelsin -L --show-trace
        nixos-rebuild --target-host ramona@evillian --use-remote-sudo switch --flake .#evillian -L --show-trace
      '')
    ];
  };
}
