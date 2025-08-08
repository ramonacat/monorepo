{
  inputs,
  local-packages,
}: let
  overlays = let
    common = [
      (import inputs.rust-overlay)
    ];
    mine = import ./overlay.nix;
  in {
    x86_64 =
      common
      ++ [
        inputs.nix-minecraft.overlay
        (mine "x86_64" {inherit inputs local-packages;})
      ];
  };
  pkgsConfig = {
    allowUnfree = true;
    android_sdk.accept_license = true;
    permittedInsecurePackages = [
      "libsoup-2.74.3"
    ];
  };
in
  import inputs.nixpkgs {
    overlays = overlays.x86_64;
    system = "x86_64-linux";
    config =
      pkgsConfig
      // {
        packageOverrides = pkgs: {
          # Dark magic for transcoding acceleration on hallewell
          vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
        };
      };
  }
