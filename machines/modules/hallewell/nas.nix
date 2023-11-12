{ config, pkgs, lib, ... }:
{
  config = {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
    users.users.nas = {
      isSystemUser  = false;
      uid = 16969;
      group = "nas";
    };
    users.groups.nas = {};
    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /mnt/nas3/data 10.69.10.0/24(rw,sync,all_squash,anonuid=16969,no_subtree_check,insecure) 100.0.0.0/8(rw,sync,all_squash,anonuid=16969,no_subtree_check,insecure)
    '';
    networking.firewall.allowedTCPPorts = [ 20048 2049 111 ];

    services.samba-wsdd.enable = true;

    services.samba = {
      enable = true;
      openFirewall = true;
      securityType = "user";
      extraConfig = ''
        workgroup = WORKGROUP
        server string = smbnix
        netbios name = smbnix
        security = user 
        #use sendfile = yes
        #max protocol = smb2
        # note: localhost is the ipv6 localhost ::1
        hosts allow = 100. 10.69.10. 127.0.0.1 localhost
        hosts deny = 0.0.0.0/0
        guest account = nas
        map to guest = bad user
        acl allow execute always = True
      '';
      shares = {
        public = {
          path = "/mnt/nas3/data";
          browseable = "yes";
          writeable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "nas";
          "force group" = "nas";
        };
      };
    };

    # Backups
    systemd.services.backup = {
      after = [ "network.target" ];
      description = "Backup the NAS";
      serviceConfig = {
        Type = "oneshot";
        User = "ramona"; # This user must have the b2 credentials configured for rclone
        ExecStart = "${pkgs.rclone}/bin/rclone --verbose --transfers 32 sync /mnt/nas3/data/ b2:ramona-fun-nas-backup/";
      };
    };

    systemd.timers.backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1h";
        OnUnitActiveSec = "1h";
        Unit = "backup.service";
      };
    };

    # Dark magic for transcoding acceleration
    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };
  };
}
