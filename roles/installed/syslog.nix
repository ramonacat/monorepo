_: {
  config = {
    services.rsyslogd = {
      enable = true;
      defaultConfig = ''
        $ActionQueueType LinkedList # use asynchronous processing
        # $ActionQueueFileName srvrfwd # set file name, also enables disk mode
        $ActionResumeRetryCount -1 # infinite retries on insert failure
        $ActionQueueSaveOnShutdown on # save in-memory data if rsyslog shuts down

        action(type="omfwd" Target="syslog.infrastructure.ramona.fun" Port="6514" Protocol="tcp")
      '';
    };
  };
}
