_: {
  networking.hostName = "depraysie";

  ramona.router = {
    enabled = true;
    interfaces = [
      {
        name_pattern = "enp0s31f6";
        cost = 100;
        kind = "Broadcast";
      }
    ];
  };
}
