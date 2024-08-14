{
  lib,
  config,
  pkgs,
  ...
}: {
  age.secrets.ras2-db-config = {
    file = ../../secrets/ras2-db-config.age;
    group = "ras2";
    mode = "440";
  };
  services.phpfpm.pools.ras2 = {
    user = "ras2";
    settings = {
      "listen.owner" = config.services.nginx.user;
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
    phpEnv."PATH" = lib.makeBinPath [
      (pkgs.php82.buildEnv {
        extensions = {
          enabled,
          all,
        }:
          enabled ++ [all.xdebug];
        extraConfig = ''
          zend.exception_string_param_max_len=128
        '';
      })
    ];
    phpEnv."DATABASE_CONFIG" = config.age.secrets.ras2-db-config.path;
  };

  services.nginx = {
    enable = true;
    virtualHosts."ras2.ramona.fun".locations."/" = {
      root = "${pkgs.ramona.ras2}/share/php/ras2/public/";
      extraConfig = ''
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${config.services.phpfpm.pools.ras2.socket};
        include ${pkgs.nginx}/conf/fastcgi.conf;
      '';
    };
  };
  users.users.ras2 = {
    isSystemUser = true;
    group = "ras2";
  };

  users.groups.ras2 = {};

  systemd.services.phpfpm-ras2 = {
    preStart = "cd ${pkgs.ramona.ras2}/share/php/ras2/; DATABASE_CONFIG=${config.age.secrets.ras2-db-config.path} ${pkgs.ramona.ras2}/share/php/ras2/vendor/bin/doctrine-migrations migrate";
  };
}
