_: {
  networking.hostName = "blackwood";
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "10.69.0.0/16"
      "100.0.0.0/8"
    ];
  };

  # so backups can skip tailscale
  networking.firewall.allowedTCPPorts = [22];
}
