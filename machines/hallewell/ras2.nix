{
  lib,
  config,
  pkgs,
  ...
}: let
  phpPackage = pkgs.php83.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled ++ [all.xdebug];
    extraConfig = ''
      zend.exception_string_param_max_len=128
    '';
  };
in {
  age.secrets.ras2-telegraf-db-config = {
    file = ../../secrets/ras2-telegraf-db-config.age;
    group = "ras2";
    mode = "440";
  };
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
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
    phpEnv = {
      "APPLICATION_MODE" = "prod";
      "PATH" = lib.makeBinPath [
        phpPackage
      ];
      "DATABASE_CONFIG" = config.age.secrets.ras2-db-config.path;
      "DATABASE_CONFIG_TELEGRAF" = config.age.secrets.ras2-telegraf-db-config.path;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."hallewell.ibis-draconis.ts.net".locations."/" = {
      root = "${pkgs.ramona.ras2}/share/php/ras2/public/";

      extraConfig = ''
        try_files $uri $uri/ /index.php$is_args$args;
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

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [80 443];

  users.groups.ras2 = {};

  systemd = {
    services.phpfpm-ras2 = {
      preStart = "cd ${pkgs.ramona.ras2}/share/php/ras2/; DATABASE_CONFIG=${config.age.secrets.ras2-db-config.path} ${pkgs.ramona.ras2}/share/php/ras2/vendor/bin/doctrine-migrations migrate";
    };

    services.db-maintenance = {
      script = "DATABASE_CONFIG=${config.age.secrets.ras2-db-config.path} DATABASE_CONFIG_TELEGRAF=${config.age.secrets.ras2-telegraf-db-config.path} ${phpPackage}/bin/php ${pkgs.ramona.ras2}/share/php/ras2/bin/run-maintenance.php";
    };

    timers.db-maintenance = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        Persistent = true;
        RandomizedDelaySec = "30min";
        Unit = "db-maintenance.service";
      };
    };
  };
}
