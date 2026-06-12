{ config, ... }: {
  config = {
    networking = {
      hostName = config.ramona.darkmore-control-plane.hostname;
    };
  };
}
