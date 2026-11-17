{
  lib,
  config,
  pkgs,
  ...
}:
{
  config =
    let
      klib = import ./_lib.nix { inherit lib config; };
    in
    {
      ramona = {
        vault-agent.templates =
          (lib.mapAttrsToList (name: value: {
            contents = ''
              {{- with pkiCert "${value.parent_ca}/issue/${value.issuer}" "common_name=${value.common_name}" "alt_names=${lib.join "," value.hosts}" "ip_sans=${lib.join "," value.ips}" "ttl=24h" -}}
              {{ .Cert }}{{ .CA }}{{ .Key }}
              {{ .Cert | writeToFile "${klib.certificate-path name "crt"}" "${value.owner_user}" "${value.owner_group}" "0644" }}
              {{ .Key | writeToFile "${klib.certificate-path name "key"}" "${value.owner_user}" "${value.owner_group}" "0400" }}
              {{- end -}}
            '';
            destination = "/var/ramona/kubernetes/certificates/${lib.defaultTo name value.pathname_override}";
          }) config.ramona.kubernetes.certificates)
          ++ (lib.mapAttrsToList (name: value: {
            contents = ''
              {{- with pkiCert "pki-kubernetes-${config.ramona.kubernetes.cluster-name}/issue/${value.issuer}" "common_name=${value.common_name}" "ttl=24h" -}}
              {{ .Cert }}{{ .CA }}{{ .Key }}
              {{ .Cert | writeToFile "/var/ramona/kubernetes/certificates/accounts/${value.config_file}.crt" "kubernetes" "kubernetes" "0644" }}
              {{ .Key | writeToFile "/var/ramona/kubernetes/certificates/accounts/${value.config_file}.key" "kubernetes" "kubernetes" "0400" }}
              {{- end -}}
            '';
            destination = "/var/ramona/kubernetes/certificates/account/${value.config_file}.bundle";
            exec = [
              {
                command = [
                  "${pkgs.ramona.r}/bin/r"
                  "kubernetes"
                  "create-config"
                  name
                  (../../certificates + "/ca-kubernetes-${config.ramona.kubernetes.cluster-name}.crt")
                  "/var/ramona/kubernetes/certificates/accounts/${value.config_file}.crt"
                  "/var/ramona/kubernetes/certificates/accounts/${value.config_file}.key"
                  "127.0.0.1"
                  (klib.kubeconfig-path name)
                ];
              }
            ];
          }) config.ramona.kubernetes.accounts)
          ++ [
            {
              contents = ''
                {{- with secret "secrets/kubernetes/${config.ramona.kubernetes.cluster-name}/cluster/service-account-key" -}}
                    {{ .Data.data.key | writeToFile "${config.ramona.kubernetes.service-account-key.key}" "kubernetes" "kubernetes" "0644" }}
                    {{ .Data.data.pub | writeToFile "${config.ramona.kubernetes.service-account-key.pub}" "kubernetes" "kubernetes" "0400" }}
                {{- end -}}
              '';
              destination = "/var/ramona/kubernetes/certificates/service-account-key";
            }
          ];

        kubernetes.service-account-key = {
          key = "/etc/kubernetes/pki/sa.key";
          pub = "/etc/kubernetes/pki/sa.pub";
        };

        ca-certificates."${config.ramona.kubernetes.cluster-name}" = {
          cluster = ../../certificates + "/ca-kubernetes-${config.ramona.kubernetes.cluster-name}.crt";
          etcd = ../../certificates + "/ca-kubernetes-${config.ramona.kubernetes.cluster-name}-etcd.crt";
          front-proxy =
            ../../certificates + "/ca-kubernetes-${config.ramona.kubernetes.cluster-name}-front-proxy.crt";
        };
      };
    };
  options = {
    ramona.ca-certificates = lib.mkOption {
      type = with lib.types; attrsOf (attrsOf pathInStore);
    };
    ramona.kubernetes.service-account-key = lib.mkOption {
      type =
        with lib.types;
        submodule {
          options = {
            key = lib.mkOption { type = path; };
            pub = lib.mkOption { type = path; };
          };
        };
    };
  };
}
