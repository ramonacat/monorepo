{pkgs, craneLib}:
    let
      packageArguments = {
        src = pkgs.lib.cleanSourceWith {
          src = craneLib.path ../apps/bar;
        };
        buildInputs = with pkgs; [
          pkg-config
          pipewire
          clang
        ];
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      };
      cargoArtifacts = craneLib.buildDepsOnly packageArguments;
      in
      craneLib.buildPackage (packageArguments // {
        inherit cargoArtifacts;
      })
