{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    ./_all/base.nix
    ./_all/bcachefs.nix
    ./_all/kernel.nix
    ./_all/locale.nix
    ./_all/networking.nix
    ./_all/nix.nix
    ./_all/pam.nix
    ./_all/ssh.nix
  ];
}
