{
  config,
  pkgs,
  ...
}: {
  config = let
    certificateDirectory = "/var/tailscale-ssl/nginx/";
    certificateFile = "${certificateDirectory}/certificate.cert";
    certificateKey = "${certificateDirectory}/certificate.key";
  in {
    services.nginx = {
      enable = true;
      virtualHosts."${config.networking.hostName}.ibis-draconis.ts.net" = {
        addSSL = true;
        sslCertificate = certificateFile;
        sslCertificateKey = certificateKey;
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
      config.services.nginx.defaultSSLListenPort
    ];
    systemd = {
      services.nginx-tailscale-ssl-keyrefresh = {
        path = ["/run/current-system/sw/"];
        script = "${pkgs.tailscale}/bin/tailscale cert --cert-file=${certificateFile} --key-file=${certificateKey} --min-validity=2160h ${config.networking.hostName}.ibis-draconis.ts.net && chown ${config.services.nginx.user}:${config.services.nginx.group} ${certificateDirectory}/* && systemctl reload nginx";
      };

      timers.nginx-tailscale-ssl-keyrefresh = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnUnitActiveSec = "85d";
          Persistent = true;
          Unit = "nginx-tailscale-ssl-keyrefresh.service";
        };
      };

      tmpfiles.rules = [
        "d '${certificateDirectory}' - ${config.services.nginx.user} ${config.services.nginx.group} - -"
      ];
    };
    ramona.roles = ["tailscale-nginx"];
  };
}
