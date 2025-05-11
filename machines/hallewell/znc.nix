_: {
  config = {
    services.znc = {
      enable = true;
      mutable = false;
      useLegacyConfig = false;
      openFirewall = false;

      config = {
        LoadModule = ["adminlog simple_away"];
        User.ramona = {
          Admin = true;
          Pass.password = {
            Method = "sha256";
            Hash = "e1fc23065a30ed99ba9394f5c98cd77dc1850440939155cdaf6cd30980b28dfc";
            Salt = "zf?0a7:-C/;WN-_o9x,+";
          };
          Network.oftc = {
            Server = "irc.oftc.net +6697";
            Chan = {"#bcache" = {};};
            Nick = "ramonacat";
          };
        };
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [5000];
  };
}
