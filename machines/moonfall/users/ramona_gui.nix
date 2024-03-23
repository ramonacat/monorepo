{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    users.users.ramona = {
      extraGroups = ["libvirtd" "openrazer"];
    };
    home-manager.users.ramona = {
      home.packages = with pkgs; [
        polychromatic
        looking-glass-client
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
      wayland.windowManager.sway = {
        extraConfigEarly = ''
        '';
        config = {
          output = {
            "Dell Inc. DELL U2723QE HRJH2P3" = {
              scale = "1.5";
              pos = "0 0";
              bg = "/dev/null fill #000000";
              render_bit_depth = "8";
            };
            "Dell Inc. DELL U2720Q JKPQT83" = {
              scale = "1.5";
              pos = "2560 0";
              bg = "/dev/null fill #000000";
              render_bit_depth = "8";
            };
            "Dell Inc. DELL U2723QE 6MMF1P3" = {
              scale = "1.5";
              pos = "5120 0";
              bg = "/dev/null fill #000000";
              render_bit_depth = "8";
            };
          };
        };
      };
    };
  };
}
