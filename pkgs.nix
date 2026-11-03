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
      agenix = inputs.agenix.packages."${system}".default;
    })
    (final: prev: {
      inherit (prev.lixPackageSets.stable)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena
        ;
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
