{
  inputs,
  local-packages,
  system,
}:
let
  overlays = [
    (import inputs.rust-overlay)
    (_: prev: {
      ramona = prev.lib.mapAttrs (_: v: v.package) local-packages.apps;
      paperless-ngx = prev.paperless-ngx.overrideAttrs (previous: {
        disabledTests = previous.disabledTests ++ [
          "test_mail"
          "test_slow_write_incomplete"
        ];
      });
      tflint = prev.callPackage ./overrides/tflint.nix { };
      agenix = inputs.agenix.packages."${system}".default;
      openiscsi = prev.openiscsi.overrideAttrs (_: {
        patches = prev.fetchurl {
          url = "https://github.com/open-iscsi/open-iscsi/commit/8112cdd9514df076dc64ca3d4e85283aa701ce7e.patch";
          hash = "sha256-PMqnKPqAC95KTB4T4Ticy9hHEZ1F/w+nZ6TZJaS/iIw=";
        };
      });
    })
  ];
  pkgsConfig = {
    allowUnfree = true;
    android_sdk.accept_license = true;
  };
in
import inputs.nixpkgs {
  inherit overlays system;

  config = pkgsConfig // {
    packageOverrides = pkgs: {
      # Dark magic for transcoding acceleration on hallewell
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
  };
}
