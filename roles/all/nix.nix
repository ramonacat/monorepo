{ inputs, ... }:
let
  nixpkgsPath = "/etc/channels/nixpkgs";
in
{
  config = {
    nix = {
      registry.nixpkgs.flake = inputs.nixpkgs;
      settings = {
        trusted-users = [ "@wheel" ];
        experimental-features = [ "nix-command flakes" ];
        fallback = true;
        nix-path = [
          "nixpkgs=${nixpkgsPath}"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "L+ ${nixpkgsPath}  - - - - ${inputs.nixpkgs}"
    ];
  };
}
