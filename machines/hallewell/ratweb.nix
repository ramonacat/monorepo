{pkgs, ...}: {
  config = {
    systemd.services.ratweb = {
      wantedBy = ["multi-user.target"];
      description = "ratweb!";
      serviceConfig = {
        DynamicUser = true;
        Environment = "LEPTOS_SITE_ADDR=0.0.0.0:8087";
        ExecStart = "${pkgs.ramona.ratweb}/bin/ratweb";
        WorkingDirectory = "${pkgs.ramona.ratweb}/bin/";
      };
    };
  };
}
