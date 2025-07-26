{nixpkgs}: _: let
  nixpkgsPath = "/etc/channels/nixpkgs";
in {
  config = {
    nix = {
      registry.nixpkgs.flake = nixpkgs;
      settings.trusted-users = ["@wheel"];
      settings.experimental-features = ["nix-command flakes"];
      nixPath = [
        "nixpkgs=${nixpkgsPath}"
      ];
    };

    systemd.tmpfiles.rules = [
      "L+ ${nixpkgsPath}  - - - - ${nixpkgs}"
    ];
  };
}
