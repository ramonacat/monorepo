{
  config,
  pkgs,
  ...
}: {
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
    age.secrets.telegraf-database = {
      file = ../secrets/telegraf-database.age;
      group = "telegraf";
      mode = "440";
    };

    security.sudo.extraRules = [
      {
        users = ["telegraf"];
        commands = [
          {
            command = "${smartctl_script}";
            options = ["NOPASSWD"];
          }
          {
            command = "${nvme_script}";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    services.telegraf = {
      enable = true;
      environmentFiles = [
        config.age.secrets.telegraf-database.path
      ];
      extraConfig = {
        agent.omit_hostname = false;
        outputs.postgresql = {
          connection = "postgres://telegraf:$DB_PASSWORD@hallewell/telegraf";
          timestamp_column_type = "timestamp with time zone";
          tag_cache_size = 100000;
        };
        inputs = {
          cpu = {};
          disk = {};
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
