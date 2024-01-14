{ pkgs, craneLib }:
   let 
      homeAutomationPackageArguments = {
        src = pkgs.lib.cleanSourceWith {
          src = craneLib.path ../apps/home-automation;
        };
      };
      homeAutomationPackageCargoArtifacts = craneLib.buildDepsOnly homeAutomationPackageArguments;
    in
      craneLib.buildPackage (homeAutomationPackageArguments // {
        cargoArtifacts = homeAutomationPackageCargoArtifacts;
      })
