{ config, lib, ... }: {
  certificate-path =
    name: ext:
    "/etc/kubernetes/pki/${
      lib.defaultTo name config.ramona.kubernetes.certificates."${name}".pathname_override
    }.${ext}";
  kubeconfig-path =
    name: "/etc/kubernetes/${config.ramona.kubernetes.accounts."${name}".config_file}";
}
