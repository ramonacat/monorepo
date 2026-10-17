{ config, lib, ... }: {
  config = {
    services.frr = lib.mkIf config.ramona.router.enabled {
      configFile = config.ramona.router.frr_config;
      ospfd = {
        enable = true;
      };
      bfdd = {
        enable = true;
      };
    };
  };
}
