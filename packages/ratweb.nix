{
  pkgs,
  craneLib,
}: let
  mkRustPackage = import ../libs/nix/mkRustPackage.nix;
in
  mkRustPackage {
    inherit pkgs craneLib;
    srcPath = ../.;
    additionalPackageArguments = {src}: {
      sourceRoot = "${src.name}/apps/ratweb/";
      cargoToml = "${src}/apps/ratweb/Cargo.toml";
      cargoLock = "${src}/apps/ratweb/Cargo.lock";
    };
    sourceFilter = path: type: craneLib.filterCargoSources path type || (builtins.match ".*\\.scss$" path != null);
    buildAdditionalPackageArguments = {...}: {
      buildInputs = with pkgs; [
        cargo-leptos
        binaryen
        dart-sass
      ];
      buildPhaseCargoCommand = "cargo leptos build --release -vvv";
      installPhaseCommand = ''
        mkdir -p $out/bin/target
        cp target/release/ratweb $out/bin/
        cp -r target/site $out/bin/target/
      '';
    };
  }
