{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./host-tailscale/webdav.nix
    ./host-tailscale/nixos-builds.nix
  ];
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

        # these are hallewell's tailscale addresses
        listenAddresses = ["100.109.240.138" "[fd7a:115c:a1e0:ab12:4843:cd96:626d:f08a]"];
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
