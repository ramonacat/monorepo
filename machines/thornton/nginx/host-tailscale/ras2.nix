{
  pkgs,
  config,
  ...
}: {
  config = {
    services.nginx.virtualHosts."${config.networking.hostName}.ibis-draconis.ts.net".locations = {
      "~ /ras/.*" = {
        root = "${pkgs.ramona.ras2}/share/php/ras2/public/";

        extraConfig = ''
          try_files $uri $uri/ @php-ras;
        '';
      };
      "@php-ras" = {
        root = "${pkgs.ramona.ras2}/share/php/ras2/public/";

        extraConfig = ''
          rewrite ^/ras/(.*)$ /$1 break;
          fastcgi_split_path_info ^((.*))$;
          fastcgi_pass unix:${config.services.phpfpm.pools.ras2.socket};

          include ${pkgs.nginx}/conf/fastcgi.conf;

          fastcgi_param SCRIPT_FILENAME $document_root/index.php;
          fastcgi_param SCRIPT_NAME /index.php;
          fastcgi_param REQUEST_URI $uri$is_args$args;
        '';
      };
    };
  };
}
