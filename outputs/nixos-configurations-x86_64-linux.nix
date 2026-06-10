{
  pkgs,
  inputs,
  flake,
  ...
}:
let
  machines = pkgs.lib.mapAttrsToList (hostname: _: hostname) (builtins.readDir ../machines);
in
pkgs.lib.genAttrs machines (
  hostname:
  inputs.nixpkgs.lib.nixosSystem {
    inherit pkgs;
    system = "x86_64";
    specialArgs = {
      inherit inputs flake;
    };
    modules = [
      (../machines + "/${hostname}")
    ];
  }
)
// pkgs.lib.mergeAttrsList (
  map (
    i:
    let
      set-name = "darkmore-control-plane";
      hostname = "${set-name}-${toString i}";
    in
    {
      "${hostname}" = inputs.nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64";
        specialArgs = {
          inherit inputs flake;
        };
        modules = [
          (../machine-templates + "/${set-name}")
          {
            config = {
              ramona.darkmore-control-plane = {
                id = i;
                total-count = 3;
              };
            };
          }
        ];
      };
    }
  ) (pkgs.lib.range 0 2)
)
