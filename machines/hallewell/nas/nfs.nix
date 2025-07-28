{config, ...}: {
  config = {
    services.nfs.server = {
      enable = true;
      exports = let
        anonuid = config.users.users.nas.uid;
        paths = import ../../../data/paths.nix;
        options = "rw,sync,all_squash,anonuid=${builtins.toString anonuid},no_subtree_check,insecure";
      in ''
        ${paths.hallewell.nas-share} 10.69.10.0/24(${options}) 100.0.0.0/8(${options})
      '';
    };
    networking.firewall.allowedTCPPorts = [
      20048 # NFS mountd
      2049 # nfsd
      111 # nfsd/rpcbind
    ];
  };
}
