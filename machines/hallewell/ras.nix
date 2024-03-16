{...}: {
  config = {
    services.ramona.ras = {
      enable = true;
      dataFile = "/mnt/nas3/data/shared/todos.json";
    };

    networking.firewall.allowedTCPPorts = [8438];
  };
}
