{pkgs, ...}: {
  config = {
    systemd.services.ratweb2 = {
      wantedBy = ["multi-user.target"];
      description = "ratweb2";
      serviceConfig = {
        DynamicUser = true;
        Environment = [
          "ORIGIN=http://hallewell:8069"
          "HOST=0.0.0.0"
          "PORT=8069"
          "RAS2_SERVICE_URL=http://hallewell/ras/"
        ];
        ExecStart = "${pkgs.ramona.ratweb2}/bin/ratweb2";
      };
    };
    networking.firewall.allowedTCPPorts = [8069];
  };
}
