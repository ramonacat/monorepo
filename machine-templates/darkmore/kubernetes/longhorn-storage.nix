{ pkgs, config, ... }: {
  config = {
    environment.systemPackages = with pkgs; [ nfs-utils ];
    services.openiscsi = {
      enable = true;
      name = "iqn.2026-06.fun.ramona.iscsi:${config.networking.hostName}";
    };
    # this is a hack an it's bad but it works
    # https://github.com/ncrmro/ks-config/blob/eddd28c105d6d8544ad20dafe0c91fd8dc1ac111/hosts/common/kubernetes/longhorn.nix#L20C3-L31C5
    systemd.services.iscsi-tools = {
      description = "iSCSI tools for Longhorn";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          "${pkgs.coreutils}/bin/mkdir -p /usr/bin"
          "${pkgs.coreutils}/bin/ln -sf ${pkgs.openiscsi}/bin/iscsiadm /usr/bin/iscsiadm"
          "${pkgs.coreutils}/bin/ln -sf ${pkgs.util-linux}/bin/mount /usr/bin/mount"
          "${pkgs.coreutils}/bin/ln -sf ${pkgs.nfs-utils}/bin/mount.nfs /usr/bin/mount.nfs"
        ];
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };

    boot.kernelModules = [ "dm_crypt" ];
  };
}
