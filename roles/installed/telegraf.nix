{pkgs, ...}: {
  config = let
    smartctl_script = pkgs.writeScript ''smartctl-wrapper'' ''
      #!${pkgs.stdenv.shell}
      /run/wrappers/bin/sudo ${pkgs.smartmontools}/bin/smartctl "$@"
    '';
    nvme_script = pkgs.writeScript ''nvme-wrapper'' ''
      #!${pkgs.stdenv.shell}
      /run/wrappers/bin/sudo ${pkgs.nvme-cli}/bin/nvme "$@"
    '';
  in {
    security.sudo.extraRules = [
      {
        users = ["telegraf"];
        commands = [
          {
            command = "${pkgs.smartmontools}/bin/smartctl";
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.nvme-cli}/bin/nvme";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    services.telegraf = {
      enable = true;
      extraConfig = {
        agent.omit_hostname = false;
        inputs = {
          cpu = {};
          disk = {
            ignore_fs = ["tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs" "efivarfs"];
            ignore_mount_opts = ["bind"];
          };
          diskio = {};
          mem = {};
          syslog = {
            server = "tcp4://:6514";
          };
          smart = {
            path_smartctl = "${smartctl_script}";
            path_nvme = "${nvme_script}";
            enable_extensions = ["auto-on"];
          };
          exec = {
            commands = ["readlink -f /nix/var/nix/profiles/system"];
            name_override = "current_closure_version";
            data_format = "value";
            data_type = "string";
          };
        };
        outputs.socket_writer = {
          address = "tcp://thornton:8094";
          content_encoding = "gzip";
          data_format = "influx";
        };
      };
    };

    services.rsyslogd = {
      enable = true;
      defaultConfig = ''
        $ActionQueueType LinkedList # use asynchronous processing
        # $ActionQueueFileName srvrfwd # set file name, also enables disk mode
        $ActionResumeRetryCount -1 # infinite retries on insert failure
        $ActionQueueSaveOnShutdown on # save in-memory data if rsyslog shuts down

        # forward over tcp with octet framing according to RFC 5425
        *.* @@(o)127.0.0.1:6514;RSYSLOG_SyslogProtocol23Format
      '';
    };
  };
}
