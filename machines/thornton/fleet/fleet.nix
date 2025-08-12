{config, ...}: {
  config = {
    age.secrets = {
      fleet-mdm-wstep-cert = {
        file = ../../../secrets/fleet-mdm-wstep-cert.age;
        owner = "fleet";
        group = "fleet";
      };
      fleet-mdm-wstep-key = {
        file = ../../../secrets/fleet-mdm-wstep-key.age;
        owner = "fleet";
        group = "fleet";
      };
    };

    virtualisation.oci-containers.containers.fleet = {
      image = "fleetdm/fleet:HEAD";
      ports = ["127.0.0.1:8080:8080"];
      environment = {
        FLEET_MYSQL_ADDRESS = "/var/run/mysqld/mysqld.sock";
        FLEET_MYSQL_PROTOCOL = "unix";
        FLEET_REDIS_ADDRESS = "host.containers.internal:6379";
        FLEET_SERVER_TLS = "false";
        FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT = config.age.secrets.fleet-mdm-wstep-cert.path;
        FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY = config.age.secrets.fleet-mdm-wstep-key.path;
      };
      user = "${builtins.toString config.users.users.fleet.uid}:${builtins.toString config.users.groups.fleet.gid}";
      volumes = [
        "/var/run/mysqld/mysqld.sock:/var/run/mysqld/mysqld.sock"
        "${config.age.secrets.fleet-mdm-wstep-cert.path}:${config.age.secrets.fleet-mdm-wstep-cert.path}"
        "${config.age.secrets.fleet-mdm-wstep-key.path}:${config.age.secrets.fleet-mdm-wstep-key.path}"
      ];
      cmd = ["/bin/sh" "-c" "fleet prepare db --no-prompt && fleet serve"];
    };

    users.users.fleet = {
      isSystemUser = true;
      group = "fleet";
      uid = 993;
    };

    users.groups.fleet = {
      gid = 990;
    };
  };
}
