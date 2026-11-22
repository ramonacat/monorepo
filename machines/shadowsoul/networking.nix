_: {
  config = {
    networking.hostName = "shadowsoul";

    ramona = {
      # this isn't really great, because this is the router id, which should probably be only used for management, there should probably be a seprate subnet just for this host
      home-subnet = "10.255.232.0/21";

      router = {
        enabled = true;
      };

      wireguard = {
        enabled = true;
        host = "d.rumanowski.com";
        available_ports = [ 49152 ];
      };
    };
  };
}
