{
  inputs,
  local-packages,
  system,
}: let
  overlays = [
    (import inputs.rust-overlay)
    (_: prev: {
      ramona = prev.lib.mapAttrs (_: v: v.package) local-packages.apps;
      bcachefs-tools = prev.bcachefs-tools.overrideAttrs (_: {
        version = "1.35.0-dev";
        src = prev.fetchFromGitHub {
          owner = "koverstreet";
          repo = "bcachefs-tools";
          rev = "dca1a7bd60e5fb52f172cb793c2fe946f35c86a0";
          hash = "sha256-I1qaq6zrv4iA/5kL9MmxEEDM2Fk3r37VtptGNyXX03A=";
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

    config =
      pkgsConfig
      // {
        packageOverrides = pkgs: {
          # Dark magic for transcoding acceleration on hallewell
          vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
        };
      };
  }
