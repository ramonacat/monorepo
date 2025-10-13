{
  config,
  pkgs,
  ...
}: {
  config = {
    services.telegraf = {
      extraConfig = {
        agent = {
          snmp_translator = "gosmi";
        };
        inputs = {
          file = {
            files = ["/var/www/${config.networking.hostName}.ibis-draconis.ts.net/builds/*-closure"];
            data_format = "value";
            data_type = "string";
            name_override = "latest_closure";
            file_tag = "filename";
          };
          snmp = {
            agents = [
              "udp://10.69.10.1:161"
              "udp://10.69.10.2:161"
              "udp://10.69.10.3:161"
            ];
            version = 2;
            community = "public";
            path = ["${pkgs.net-snmp.out}/share/snmp/mibs/"];
            field = [
              {
                oid = "RFC1213-MIB::sysName.0";
                name = "sysName";
                is_tag = true;
              }
            ];
            table = [
              {
                oid = "IF-MIB::ifTable";
                name = "snmp_interface";
                inherit_tags = ["sysName"];
                field = [
                  {
                    oid = "IF-MIB::ifDescr";
                    name = "ifDescr";
                    is_tag = true;
                  }
                  {
                    oid = "IF-MIB::ifSpeed";
                    name = "ifSpeed";
                  }
                  {
                    oid = "IF-MIB::ifOperStatus";
                    name = "ifOperStatus";
                  }
                  {
                    oid = "IF-MIB::ifInOctets";
                    name = "ifInOctets";
                  }
                  {
                    oid = "IF-MIB::ifInDiscards";
                    name = "ifInDiscards";
                  }
                  {
                    oid = "IF-MIB::ifInErrors";
                    name = "ifInErrors";
                  }
                  {
                    oid = "IF-MIB::ifOutOctets";
                    name = "ifOutOctets";
                  }
                  {
                    oid = "IF-MIB::ifOutDiscards";
                    name = "ifOutDiscards";
                  }
                  {
                    oid = "IF-MIB::ifOutErrors";
                    name = "ifOutErrors";
                  }
                ];
              }
            ];
          };
        };
      };
    };
  };
}
