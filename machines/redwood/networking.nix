_: {
  config = {
    networking = {
      hostName = "redwood";

      # FIXME hack to allow initial tailscale setup
      firewall.allowedTCPPorts = [22];
    };
  };
}
