{modulesPath, ...}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")] ++ import ../../libs/nix/nix-files-from-dir.nix ./.;
}
