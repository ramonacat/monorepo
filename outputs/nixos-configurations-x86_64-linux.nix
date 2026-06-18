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
  let
    k8s-config = (builtins.fromJSON (builtins.readFile ../terraform/k8s-nodes.json)).darkmore;
  in
  map (
    node:
    let
      set-name = "darkmore-control-plane";
    in
    {
      "${node.hostname}" = inputs.nixpkgs.lib.nixosSystem {
        inherit pkgs;
        system = "x86_64";
        specialArgs = {
          inherit inputs flake;
        };
        modules = [
          (../machine-templates + "/${set-name}")
          {
            config = {
              ramona = {
                kubernetes.podCidr = k8s-config.podCidr;
                kubernetes.hostPodCidr = node.podCidr;
                darkmore-control-plane = {
                  inherit (node) ip hostname;

                  all-nodes = map (node: { inherit (node) ip hostname; }) k8s-config.nodes;
                };
              };
            };
          }
        ];
      };
    }
  ) k8s-config.nodes
)
