{ pkgs, config, ... }: {
  config = {
    environment.systemPackages = with pkgs; [ openiscsi ];
    services.openiscsi = {
      enable = true;
      name = "iqn.2026-06.fun.ramona.iscsi:${config.networking.hostName}";
    };
  };
}
