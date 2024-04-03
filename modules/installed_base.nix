{
  lib,
  pkgs,
  ...
}: {
  config = {
    services = {
      openssh = {
        enable = true;
        openFirewall = false;
        settings.X11Forwarding = true;
      };
      fwupd.enable = lib.mkDefault true;
      tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        extraUpFlags = ["--advertise-exit-node"];
      };
    };
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];
    environment.systemPackages = with pkgs; [pciutils tailscale];
    security.polkit.enable = true;

    services.udev.packages = with pkgs; [yubikey-personalization libu2f-host];
    services.pcscd.enable = true;
    security.pam.u2f = {
      enable = true;
      cue = true;
      appId = "local";
      origin = "local";
      authFile = pkgs.writeText "u2f-auth-file" ''
        ramona:bhqayNhwfHB5u4bgnlYoJVG5QY6sbHYeUoReCV+xVFQB5wqo3HmzSi+d18VywFdDFJgLbQ/JHhM2PjuRM/yRoQ==,sj6KisA0vqMF4EPD4mFVBDbsKxHwjVbwc/WspsTRma7FHJwK7yGUb1uH2KdASrZxW+Q3lCrGnJl9U9yLP9RrQQ==,es256,+presence
        ramona:hwPvtJt4xtmklNLCEdINbFf7ZOjq48weK/iDL8iat0Muw6zb/DuZEYCLgf1hP04L1JlvGAgx1aNIbq1fVUIkHg==,N3BQ+NWRHYpj4g98qY+BLKmygQA4bVVYBKNgVi0joJRxTsJ//kgTnlEI69SLjo31VRSjrOsTfoyDfn14mBMGHA==,es256,+presence
        ramona:owBYeUbJfgvfH7h09pyOqBzI++jgrPprXpfS5yR5Cg1GvSYPPHYRFPYMvfOmImFynYMQFHGDEzt+jJLIGEdMima9RCsRZnijBN/xejlgSRuemmdqdJJ1x2rPQWXbn86A2SMJBa13Xr0rcO5RWxOzgq7kzAaltfeueyEetHwBTD8Kxwh0tsKhvNuVCAJQbxMzHAfVtsP3KuC/QkxG0A==,GSXkBgYCPVBVNFW968XnV/BWHJFlVGfS4WJtzmLpXckQ55FyRtfjgWF1O1XMMNmFPfCcbJuh7UTiR6Vc/w1kAA==,es256,+presence
      '';
    };
    programs.nix-ld.enable = true;

    nix.optimise.automatic = true;
    nix.gc.automatic = true;
  };
}
