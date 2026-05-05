{
  inputs,
  local-packages,
  system,
}: let
  overlays = [
    (import inputs.rust-overlay)
    inputs.bun2nix.overlays.default
    (_: prev: {
      ramona = prev.lib.mapAttrs (_: v: v.package) local-packages.apps;
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
