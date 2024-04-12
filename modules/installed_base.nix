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
    security.pam.u2f = {
      enable = true;
      cue = true;
      appId = "local";
      origin = "local";
      debug = true;
      authFile = pkgs.writeText "u2f-auth-file" ''
        ramona:aPSQGcDlQwe0fzExtBKMDOw9VQgjeAKXk2y5O3yzcWJaPj8XyognBmiqYVdkSX8oKFzHc+324tQmlCC82Q/9aw==,qkAVtTymz21EM9TS0I6h1VI/qo+1XkiK6pfxDsB5EYjgedgej77I5E4Rt9xzYQUaUMg7DMOjnwgWUL6kEpvDoA==,es256,+presence
        ramona:nkhSuCIHSolJYtuxnkJwc7PPCns9FmZZgLdS3vzZQQLs2UZGV2OFpZH9igbNpUNZvn3G6ct8tzvrlCsU3RX6YA==,9nVojZVvXWhGuqfQrlXmOsdHW9TCKr5j7rAsj9mifSIoVoWDN7kYgFQLpv+eWPmCSq2QHK5mnYGhaFjX+YJpzw==,es256,+presence
        ramona:owBYesojXrbOELSCjgrDYCF9szDAIedNXz+5u/BcP/09STjnalleG++NkhXzl3m9FHw2yGqIHqzBNvxRTrLimxVYcNuJ/sujPtL0gpQejsIvvNOpOFxKJA6/AO3cIE4zLbz086JmbAm6+xobNJEYgCrseEiySeuoVElhz8tMAUwZcafkMb6PjF/Mb4MCUJyGqMuoWPJH6WKhMvfHef0=,CTIzlMzig9Vea93B84GU3I+/6tL+rAhFFumut1WA0laUe3UMycMwCX/37fXQngzg4UbzdSrSgL5mPVRWnEXvnA==,es256,+presence
      '';
    };
    programs.nix-ld.enable = true;

    nix.optimise.automatic = true;
    nix.gc.automatic = true;
  };
}
