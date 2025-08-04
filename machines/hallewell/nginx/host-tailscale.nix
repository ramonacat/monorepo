{
  pkgs,
  config,
  ...
}: {
  imports = import ../../../libs/nix/nix-files-from-dir.nix ./host-tailscale;
  config = let
    certificateDirectory = "/var/tailscale-ssl/nginx/";
    certificateFile = "${certificateDirectory}/certificate.cert";
    certificateKey = "${certificateDirectory}/certificate.key";
  in {
    services.nginx = {
      virtualHosts."hallewell.ibis-draconis.ts.net" = {
        addSSL = true;
        sslCertificate = certificateFile;
        sslCertificateKey = certificateKey;
      };
    };
    systemd = {
      services.tailscale-ssl-keyrefresh = {
        path = ["/run/current-system/sw/"];
        script = "${pkgs.tailscale}/bin/tailscale cert --cert-file=${certificateFile} --key-file=${certificateKey} --min-validity=2160h hallewell.ibis-draconis.ts.net && chown ${config.services.nginx.user}:${config.services.nginx.group} ${certificateDirectory}/* && systemctl reload nginx";
      };

      timers.tailscale-ssl-keyrefresh = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnUnitActiveSec = "85d";
          Persistent = true;
          Unit = "tailscale-ssl-keyrefresh.service";
        };
      };

      tmpfiles.rules = [
        "d '${certificateDirectory}' - ${config.services.nginx.user} ${config.services.nginx.group} - -"
      ];
    };
  };
}
