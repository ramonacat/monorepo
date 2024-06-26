{config, ...}: {
  config = {
    age.secrets.transmission-credentials = {
      file = ../../secrets/transmission-credentials.age;
      group = "transmission";
      mode = "440";
    };

    services.transmission = {
      enable = true;
      openFirewall = true;
      performanceNetParameters = true;
      credentialsFile = config.age.secrets.transmission-credentials.path;
      settings = {
        download-queue-size = 15;
        lpd-enabled = true;
        peer-limit-global = 1000;
        peer-limit-per-torrent = 500;
        peer-port = 51413;
        peer-port-random-on-start = false;
        ratio-limit = 3;
        ratio-limit-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-host-whitelist-enabled = false;
        rpc-port = 9091;
        rpc-whitelist = "127.0.0.1,::1,100.*.*.*";
        upload-slots-per-torrent = 50;
        utp-enabled = true;
      };
    };

    services.nfs.server = {
      enable = true;
      exports = ''
        /var/lib/transmission/Downloads 10.69.10.0/24(rw,sync,all_squash,anonuid=${builtins.toString config.ids.uids.transmission},no_subtree_check,insecure) 100.0.0.0/8(rw,sync,all_squash,anonuid=${builtins.toString config.ids.uids.transmission},no_subtree_check,insecure)
      '';
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [9091 20048 2049 111];
  };
}
