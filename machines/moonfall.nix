{ config, pkgs, lib, ... }:
{
  config = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "rebuild-all-machines" ''
        #!/usr/bin/env bash

        set -euo pipefail
        set -x

        nixos-rebuild --build-host ramona@caligari --use-remote-sudo switch --flake .#moonfall --show-trace
        nixos-rebuild --build-host ramona@caligari --target-host ramona@ananas --use-remote-sudo switch --flake .#ananas --show-trace
        nixos-rebuild --build-host ramona@caligari --target-host ramona@hallewell --use-remote-sudo switch --flake .#hallewell --show-trace
        nixos-rebuild --build-host ramona@caligari --target-host ramona@shadowmend --use-remote-sudo switch --flake .#shadowmend --show-trace
        nixos-rebuild --build-host ramona@caligari --target-host ramona@caligari --use-remote-sudo switch --flake .#caligari --show-trace
        nixos-rebuild --build-host ramona@caligari --target-host ramona@angelsin --use-remote-sudo switch --flake .#angelsin --show-trace
        nixos-rebuild --build-host ramona@caligari --target-host ramona@evillian --use-remote-sudo switch --flake .#evillian --show-trace
      '')
    ];
  };
}
