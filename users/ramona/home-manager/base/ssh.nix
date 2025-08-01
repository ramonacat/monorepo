{lib, ...}: {
  config = {
    programs.ssh = {
      enable = true;
      matchBlocks = let
        hosts = import ../../../../data/hosts.nix;
      in
        lib.attrsets.genAttrs hosts.nixos (hostname: {
          inherit hostname;
          forwardAgent = true;
        });
    };
  };
}
