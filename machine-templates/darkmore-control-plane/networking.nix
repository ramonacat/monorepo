{ config, ... }: {
  config = {
    networking = {
      hostName = "darkmore-control-plane-${toString config.ramona.darkmore-control-plane.id}";
    };
  };
}
