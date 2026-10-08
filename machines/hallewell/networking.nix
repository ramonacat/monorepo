_: {
  config =
    let
      secrets-path = "/var/ramona/secrets/rad/env";
    in
    {
      networking = {
        hostName = "hallewell";
      };
      ramona = {
        vault-agent.templates = [
          {
            contents = ''
              {{- with secret "secrets/hosts/hallewell/rad/env" -}}
              MIKROTIK_SCARLETWOUND_PASSWORD={{ .Data.data.MIKROTIK_SCARLETWOUND_PASSWORD }}
              {{- end -}}
            '';
            destination = secrets-path;
            command = [
              "/run/current-system/sw/bin/systemctl"
              "restart"
              "rad"
            ];
          }
        ];
        mikrotik = {
          enabled = true;
          endpoint = "10.23.2.1:8729";
          username = "rad";
          password = {
            env = "MIKROTIK_SCARLETWOUND_PASSWORD";
          };
          wireguard = {
            endpoint = "InitiatorOnly";
          };
        };
      };
      systemd.services.rad.serviceConfig = {
        EnvironmentFile = secrets-path;
      };
    };
}
