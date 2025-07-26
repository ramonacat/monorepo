{nixpkgs}: {modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (import ./_all/nix.nix {inherit nixpkgs;})

    ./_all/base.nix
    ./_all/bcachefs.nix
    ./_all/kernel.nix
    ./_all/locale.nix
    ./_all/networking.nix
    ./_all/pam.nix
    ./_all/ssh.nix
  ];
}
