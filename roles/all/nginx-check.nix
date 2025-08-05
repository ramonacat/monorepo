{
  lib,
  config,
  ...
}: {
  config = {
    system.activationScripts = lib.mkIf config.services.nginx.enable {
      nginx-config-test = ''
        ${config.services.nginx.package}/bin/nginx -t -c ${config.services.nginx.config}
      '';
    };
  };
}
