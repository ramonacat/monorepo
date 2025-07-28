_: {
  config = {
    services.samba-wsdd.enable = true;

    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        "global" = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          # note: localhost is the ipv6 localhost ::1
          "hosts allow" = "100. 10.69.10. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nas";
          "map to guest" = "bad user";
          "acl allow execute always" = true;
        };
        public = let
          paths = import ../../../data/paths.nix;
        in {
          path = paths.hallewell.nas-share;
          browseable = "yes";
          writeable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0775";
          "directory mask" = "0755";
          "force user" = "nas";
          "force group" = "nas";
        };
      };
    };
  };
}
