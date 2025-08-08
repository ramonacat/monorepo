{
  modulesPath,
  inputs,
  ...
}: {
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      inputs.home-manager.nixosModules.home-manager
      inputs.lix-module.nixosModules.default
    ]
    ++ import ../../libs/nix/nix-files-from-dir.nix ./.;
}
