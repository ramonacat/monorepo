{
  config,
  pkgs,
  ...
}: {
  config = {
    age.secrets.telegraf-database = {
      file = ../secrets/telegraf-database.age;
      group = "telegraf";
      mode = "440";
    };

    users.users.telegraf.extraGroups = ["wheel"];

    services.telegraf = let
      smartctl_script = pkgs.writeScript ''smartctl-wrapper'' ''
        #!${pkgs.stdenv.shell}
        /run/wrappers/bin/sudo ${pkgs.smartmontools}/bin/smartctl "$@"
      '';
      nvme_script = pkgs.writeScript ''nvme-wrapper'' ''
        #!${pkgs.stdenv.shell}
        /run/wrappers/bin/sudo ${pkgs.nvme-cli}/bin/nvme "$@"
      '';
    in {
      enable = true;
      environmentFiles = [
        config.age.secrets.telegraf-database.path
        (pkgs.writeText "telegraf-environment" ''
          SMARTCTL_PATH=${smartctl_script}
          NVME_PATH=${nvme_script}
        '')
      ];
      extraConfig = {
        agent.omit_hostname = false;
        outputs.postgresql = {
          connection = "postgres://telegraf:$DB_PASSWORD@hallewell/telegraf";
          timestamp_column_type = "timestamp with time zone";
          tag_cache_size = 100000;
        };
        inputs.cpu = {};
        inputs.disk = {};
        inputs.diskio = {};
        inputs.ethtool = {};
        inputs.smart = {
          path_smartctl = "$SMARTCTL_PATH";
          path_nvme = "$NVME_PATH";
        };
        inputs.syslog = {
          server = "tcp4://:6514";
        };
        inputs.exec = {
          commands = ["readlink -f /nix/var/nix/profiles/system"];
          name_override = "current_closure_version";
          data_format = "value";
          data_type = "string";
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
