{...}: {
  config = {
    services.epmd.listenStream = "0.0.0.0:4369";
    services.rabbitmq = {
      enable = true;
      listenAddress = "0.0.0.0";
      plugins = ["rabbitmq_mqtt"];

      managementPlugin = {
        enable = true;
      };
    };

    networking.firewall.allowedTCPPorts = [5672 15672];
  };
}
