{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    ramona.vault-agent = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            role = lib.mkOption {
              type = str;
              default = "hosts";
            };
            templates = lib.mkOption {
              type = listOf attrs;
            };
          };
        };
    };
  };
  config =
    let
      client-cert = "/var/ramona/identity/certificate.crt";
      client-key = "/var/ramona/identity/certificate.key";
      ca = ../../certificates;
    in
    {
      environment.systemPackages = with pkgs; [ vault ];

      security.pki.certificateFiles = [ ca ];
      services.vault-agent.instances.main = {
        enable = true;
        settings = {
          log_level = "debug";
          vault = [
            {
              address = "https://vault.internal.ramona.fun";

              client_cert = client-cert;
              client_key = client-key;
              ca_path = ca;
            }
          ];
          auto_auth = [
            {
              enable_reauth_on_new_credentials = true;
              method = [
                {
                  type = "cert";

                  config = [
                    {
                      name = config.ramona.vault-agent.role;
                      client_cert = client-cert;
                      client_key = client-key;
                      reload = true;
                    }
                  ];
                }
              ];
            }
          ];
          template = [
            {
              contents = ''
                {{- with pkiCert "pki-hosts/issue/hosts" "common_name=${config.networking.hostName}.devices.ramona.fun" "ttl=24h" -}}
                {{ .Cert }}{{ .CA }}{{ .Key }}
                {{ .Cert | writeToFile "${client-cert}" "root" "root" "0644" }}
                {{ .Key | writeToFile "${client-key}" "root" "root" "0400" }}
                {{- end -}}
              '';
              destination = "/var/ramona/identity/bundle";
            }
          ]
          ++ config.ramona.vault-agent.templates;
        };
      };
    };
}
