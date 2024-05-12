{config, ...}: {
  config = {
    age.secrets.telegraf-database = {
      file = ../secrets/telegraf-database.age;
      group = "telegraf";
      mode = "440";
    };

    services.telegraf = {
      enable = true;
      environmentFiles = [
        config.age.secrets.telegraf-database.path
      ];
      extraConfig = {
        agent.omit_hostname = false;
        outputs.postgresql = {
          connection = "postgres://telegraf:$DB_PASSWORD@caligari/telegraf";
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
