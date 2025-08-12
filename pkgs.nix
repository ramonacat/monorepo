{
  inputs,
  local-packages,
  system,
}: let
  overlays = [
    (import inputs.rust-overlay)
    (_: prev: let
      nodejs = prev.nodejs_20;
      yarn = prev.yarn.override {inherit nodejs;};
    in {
      ramona = prev.lib.mapAttrs (_: v: v.package) local-packages.apps;
      fleet = prev.fleet.overrideAttrs (finalAttrs: oldAttrs: {
        src = prev.fetchFromGitHub {
          owner = "fleetdm";
          repo = "fleet";
          tag = "fleet-v4.71.1";
          hash = "sha256-lEgSgwygLrpkR0Kb6U/+nPRvKD5rMDvl7lxSP9Mf92k=";
        };
        vendorHash = "sha256-UOY9W2ULh2eNIfUmyU38nZCVWNTWIDTf7GBBkptrlTQ=";
        yarnOfflineCache = prev.fetchYarnDeps {
          yarnLock = finalAttrs.src + "/yarn.lock";
          hash = "sha256-UsFl9mgTq2xOstQwWtWUlmr8pflnqGFNFiKMfC0QN7E=";
        };
        doDist = false;
        yarnBuildScript = "run webpack";
        nativeBuildInputs =
          oldAttrs.nativeBuildInputs
          ++ (with prev; [
            yarnConfigHook
          ]);
        preBuild = ''
          sed -i 's/"node": ".*"/"node": "^20"/' package.json

          NODE_ENV=production ${yarn}/bin/yarn --offline run webpack

          ${prev.go-bindata}/bin/go-bindata -pkg=bindata -tags full \
              -o=server/bindata/generated.go \
              frontend/templates/ assets/... server/mail/templates
        '';
        tags = ["full" "fts5" "netgo"];
      });
    })
  ];
  pkgsConfig = {
    allowUnfree = true;
    android_sdk.accept_license = true;
    permittedInsecurePackages = [
      "libsoup-2.74.3"
    ];
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
