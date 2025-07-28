{inputs, ...}: let
  nixpkgsPath = "/etc/channels/nixpkgs";
in {
  config = {
    nix = {
      registry.nixpkgs.flake = inputs.nixpkgs;
      settings.trusted-users = ["@wheel"];
      settings.experimental-features = ["nix-command flakes"];
      nixPath = [
        "nixpkgs=${nixpkgsPath}"
      ];
    };

    systemd.tmpfiles.rules = [
      "L+ ${nixpkgsPath}  - - - - ${inputs.nixpkgs}"
    ];
  };
}
