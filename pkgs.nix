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
          rev = "0e8c88cd35b9ac3582d831a34ff26c0c1c7cc9b9";
          hash = "sha256-l2D5IuqpqF+K7Kj6amm9wBY+2beD1KFyVQh+3Eb8NLc=";
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
