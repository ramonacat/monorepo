{pkgs, ...}: {
  systemd.services.music-control = {
    wantedBy = ["multi-user.target"];
    description = "Music control";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ramona.music-control}/bin/ananas-music-control";
    };
  };
}
