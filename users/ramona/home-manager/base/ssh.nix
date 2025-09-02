{
  lib,
  flake,
  ...
}: {
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = let
        hosts = import ../../../../data/hosts.nix {inherit flake lib;};
      in
        lib.attrsets.genAttrs hosts.nixos (hostname: {
          inherit hostname;
          forwardAgent = true;
        });
    };
  };
}
