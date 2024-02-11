{ config, pkgs, lib, ... }:
{
  config = {
    services.fail2ban.enable = true;
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkRskZZaMsOngUvKYgL8K6t5FBhMurjTkqbfxNLj0wE ramona@moonfall" # this is the key that's used in CI
    ];
  };
}
