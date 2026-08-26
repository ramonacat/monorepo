_: {
  config =
    let
      secrets-path = "/var/ramona/secrets/woodpecker-agent/env";
    in
    {
      virtualisation.docker.enable = true;

      ramona.vault-agent.templates = [
        {
          contents = ''
            {{- with secret "secrets/kubernetes/darkmore/woodpecker/agent-secret" -}}
            WOODPECKER_AGENT_SECRET={{ .Data.data.WOODPECKER_AGENT_SECRET }}
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

      services.woodpecker-agents.agents.hallewell = {
        enable = true;
        environment = {
          WOODPECKER_SERVER = "woodpecker-grpc.ramona.fun";
          WOODPECKER_GRPC_SECURE = "true";
          WOODPECKER_BACKEND = "docker";
          WOODPECKER_MAX_WORKFLOWS = "4";
          WOODPECKER_KEEPALIVE_TIMEOUT = "30m";
          WOODPECKER_RETRY_TIMEOUT = "30m";
        };

        environmentFile = [ secrets-path ];
        extraGroups = [ "docker" ];
      };

      systemd.services.woodpecker-agent-hallewell.serviceConfig = {
        ReadWritePaths = [
          "/etc/woodpecker"
          "/var/run/docker.sock"
        ];
      };
    };
}
