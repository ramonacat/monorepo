_: {
  config = {
    networking.hostName = "shadowsoul";

    ramona.router = {
      enabled = true;
      wireguard = {
        host = "d.rumanowski.com";
        available_ports = [ 49152 ];
      };
    };
  };
}
