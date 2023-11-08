{ config, pkgs, lib, ... }:
{
  config = {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
    services.nfs.server.enable = true;
    services.nfs.server.exports = ''
      /mnt/nas3/data 10.69.10.0/24(rw,sync,all_squash,anonuid=65534,no_subtree_check,insecure) 100.0.0.0/8(rw,sync,all_squash,anonuid=65534,no_subtree_check,insecure)
    '';
    networking.firewall.allowedTCPPorts = [ 2049 ];

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
        guest account = nobody
        map to guest = bad user
      '';
      shares = {
        public = {
          path = "/mnt/Shares/Public";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "nobody";
          "force group" = "nogroup";
        };
      };
    };
  };
}
