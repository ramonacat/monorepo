{
  pkgs,
  config,
  ...
}:
{
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
                      name = "hosts";
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
                    {{ .Key | writeToFile "${client-key}" "root" "root" "0400" }}
                    {{ .Cert  }}
                {{- end -}}
              '';
              destination = client-cert;
              perms = "0644";
            }
          ];
        };
      };
    };
}
