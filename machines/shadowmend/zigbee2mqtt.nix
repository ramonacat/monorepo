_: {
  config = {
    services.zigbee2mqtt = {
      enable = true;

      settings = {
        frontend = {
          port = 8098;
        };
        serial = {
          port = "/dev/ttyACM0";
        };
        advanced = {
          pan_id = 30007;
          ext_pan_id = [160 113 48 240 62 4 244 87];
          channel = 15;
          network_key = [89 16 49 175 172 52 209 203 83 191 57 2 24 168 219 71];
        };
      };
    };

    networking.firewall.allowedTCPPorts = [8098];
  };
}
