{ pkgs, ... }: {
  config =
    let
      secrets-path = "/var/ramona/secrets/caddy/env";
    in
    {
      ramona.machine.tailscale-tags = [ "tag:home-front-proxy" ];
      services.tailscale.permitCertUid = "caddy";
      ramona.vault-agent.templates = [
        {
          contents = ''
            {{- with secret "secrets/hosts/hallewell/caddy/dnsimple_token" -}}
            DNSIMPLE_TOKEN={{ .Data.data.DNSIMPLE_TOKEN }}
            {{- end -}}
          '';
          destination = secrets-path;
          exec = [
            {
              command = [
                "/run/current-system/sw/bin/systemctl"
                "restart"
                "caddy"
              ];
            }
          ];
        }
      ];
      services.caddy = {
        enable = true;
        email = "ramona@luczkiewi.cz";
        openFirewall = true;
        environmentFile = secrets-path;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/caddy-dns/dnsimple@v0.0.0-20260303131243-0433343c5610"
            "github.com/mholt/caddy-webdav@v0.0.0-20260127042217-fa2f366b0d75"
          ];

          hash = "sha256-MGUZ7T6QSvNqxrP0S7ezErTIJrZ0Ehp1XJNWu5PlBT4=";
        };
        globalConfig = ''
          order webdav before file_server

          acme_dns dnsimple {$DNSIMPLE_TOKEN}
        '';
        virtualHosts."hallewell.ibis-draconis.ts.net" = {
          extraConfig =
            let
              paths = import ../../data/paths.nix;
            in
            ''
              webdav /webdav {
                  root ${paths.hallewell.nas-share}/ramona/webdav
              }
            '';
        };
        virtualHosts."assistant.home.ramona.fun" = {
          extraConfig = ''
            reverse_proxy http://homeassistant:8123
          '';
        };
      };
    };
}
