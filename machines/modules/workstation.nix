{ config, pkgs, lib, modulesPath, vscode-server, ... }:
{
  config = {
    services.vscode-server.enable = true;
    virtualisation.docker.enable = true;

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
    };
  };
}
