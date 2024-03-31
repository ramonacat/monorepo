{
  pkgs,
  craneLib,
}: let
  packageArguments = {
    src = pkgs.fetchFromGitHub {
      owner = "feschber";
      repo = "lan-mouse";
      rev = "v0.6.0";
      hash = "sha256-98n0Y9oL/ll90NKHJC/25wkav9K+eVqrO7PlrJMoGmY=";
    };
    buildInputs = with pkgs; [
      pkg-config
      xorg.libX11.dev
      xorg.libXtst
      glib.dev
      gtk4.dev
      libadwaita.dev
    ];
  };
  cargoArtifacts = craneLib.buildDepsOnly packageArguments;
in
  craneLib.buildPackage (packageArguments
    // {
      inherit cargoArtifacts;
    })
