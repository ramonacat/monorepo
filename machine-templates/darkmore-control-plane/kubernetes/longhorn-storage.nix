{ pkgs, ... }: {
  config = {
    # this is a hack an it's bad but it works
    # https://github.com/ncrmro/ks-config/blob/eddd28c105d6d8544ad20dafe0c91fd8dc1ac111/hosts/common/kubernetes/longhorn.nix#L20C3-L31C5
    systemd.services.iscsi-tools = {
      description = "iSCSI tools for Longhorn";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [
          "${pkgs.coreutils}/bin/mkdir -p /usr/bin"
          "${pkgs.coreutils}/bin/ln -sf ${pkgs.openiscsi}/bin/iscsiadm /usr/bin/iscsiadm"
        ];
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
