{pkgs, ...}: {
  config = {
    systemd.services.ratweb2 = {
      wantedBy = ["multi-user.target"];
      description = "ratweb2";
      serviceConfig = {
        DynamicUser = true;
        Environment = ''
          HOST=0.0.0.0
          PORT=8069
        '';
        ExecStart = "${pkgs.ramona.ratweb2}/bin/ratweb2";
        WorkingDirectory = "${pkgs.ramona.ratweb2}/lib/node_modules/ratweb2/";
      };
    };
    networking.firewall.allowedTCPPorts = [8069];
  };
}
