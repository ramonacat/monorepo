_: {
  config = {
    networking.hostName = "shadowsoul";

    ramona.router = {
      enabled = true;
    };
    ramona.wireguard = {
      enabled = true;
      host = "d.rumanowski.com";
      available_ports = [ 49152 ];
    };
  };
}
