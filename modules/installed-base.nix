{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./installed-base/restic.nix
    ./installed-base/rat.nix
  ];
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
    environment.systemPackages = with pkgs; [
      pciutils
      tailscale
      (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '')
    ];
    security.polkit.enable = true;

    services.udev.packages = with pkgs; [yubikey-personalization libu2f-host];
    security.pam.u2f = {
      enable = true;
      cue = true;
      appId = "pam://local";
      origin = "pam://local";
      debug = false;
      authFile = pkgs.writeText "u2f-auth-file" ''
        ramona:IfYfQemq431XIiaVdiGFLCxr3UIBD/PH7j4QhBDQBURLgbHwUnoP7xhbPi8xFl46GbBQ9WPInSHlffen8Hi9CQ==,rO6dkgPn/545BgDUHj+hDnvI2wf5R7SeTrrFuqWtOK0Yw8mt+dIxs9Pd8asV6dwEPlVRSWjI8zlnwUKI8PE6uA==,es256,+presence:a4QUXjAdm4kBXoobh9TlTaR5etTFRs99tQDW9sMqL9ugwq61KIU3ow99yz8BaPzCwS/fFiUHiuOk6/HFtPy6WQ==,LWxAOECZfRNuCDbLd7M2UEswECgnlC7KG2I9SXluzM/odVsM4793F17x5Pbckzk0wwwfSqGA0FPK7y9RALbahA==,es256,+presence:owBYel42czlA+alISSGNN4hym6xXBSm0bqowJ6uTpr0m1q9DgfCFPtgbFPhb1+aY6Kw3Xv7BSccvk5Uk5WQ79dYIU3FPN2ixJxDE4g8iwrtHahmAwMpKchp5VhGSfhG2ZnhedpEKYzSp05vfsYZbmuybr3nybfYoP0ZOZu/MAUzFlfLPoEcPTTJV0zUCUG9aOv+gk8Kp6YOxakFf/gY=,VRbZBBGg3qYrjiqmMLbyvelxzhWIlKD3uG324OPn+NpuIW5M7HGIULjzuhB5hq5vrL6kUCEhpjtHvUUUAc67mQ==,es256,+presence
      '';
    };
    programs.nix-ld.enable = true;

    nix.optimise.automatic = true;
    nix.gc.automatic = true;
  };
}
