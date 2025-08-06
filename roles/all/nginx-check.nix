{
  lib,
  config,
  ...
}: {
  config = {
    system.activationScripts = lib.mkIf config.services.nginx.enable {
      nginx-config-test = ''
        ${config.systemd.services.nginx.serviceConfig.ExecStart} -t
      '';
    };
  };
}
