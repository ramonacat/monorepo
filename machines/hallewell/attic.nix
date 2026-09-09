_: {
  config =
    let
      secrets-path = "/var/ramona/secrets/attic/env";
    in
    {
      ramona.vault-agent.templates = [
        {
          contents = ''
            {{- with secret "secrets/hosts/hallewell/attic/root_token" -}}
            ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64={{ .Data.data.ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 }}
            {{- end -}}
          '';
          destination = secrets-path;
          exec = [
            {
              command = [
                "/run/current-system/sw/bin/systemctl"
                "restart"
                "woodpecker-agent-main"
              ];
            }
          ];
        }
      ];
      services.atticd = {
        enable = true;
        environmentFile = secrets-path;
        settings = {
          listen = "127.0.0.1:8874";
          jwt = { };
          storage = {
            type = "local";
            path = "/mnt/nas3/attic/";
          };
          chunking = {
            nar-size-threshold = 64 * 1024;

            min-size = 512 * 1024;
            avg-size = 1024 * 1024;
            max-size = 2048 * 1024;
          };
        };
      };
    };
}
